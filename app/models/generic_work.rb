# frozen_string_literal: true
class GenericWork < Resource
  include ::CurationConcerns::WorkBehavior
  include Sufia::WorkBehavior
  include StillImageMetadata
  include TextMetadata
  include AssetMetadata
  include Permissions

  self.human_readable_type = 'Asset'
  self.indexer = AssetIndexer

  def self.aic_type
    super << AICType.Asset
  end

  type type + aic_type

  before_create :status_is_active
  validate :id_matches_uid_checksum, on: :update

  def still_image?
    type.include? AICType.StillImage
  end

  def text?
    type.include? AICType.Text
  end

  # Overrides CurationConcerns::Noid to set #id to be a MD5 checksum of #uid.
  def assign_id
    self.uid = service.mint unless new_record? && uid.present?
    self.id = service.hash(uid)
  end

  def status_is_active
    self.status = StatusType.active.uri
  end

  def id_matches_uid_checksum
    errors.add :uid, 'must match checksum' if id != service.hash(uid)
  end

  def asset_has_relationships?
    representing_resource.present?
  end

  # CurationConcerns' title is required, and is multivalued
  # We will allow it be empty, or return the pref. label as an array
  def title
    return [] unless pref_label
    [pref_label]
  end

  # Used by Sufia::WorkIndexer, although may not be required
  # Aliased to document_type
  def resource_type
    document_type
  end

  private

    def service
      @service ||= UidMinter.new(assignment_service.prefix)
    end

    def representing_resource
      @representing_resource ||= InboundRelationships.new(id)
    end

    def assignment_service
      @assignment_service ||= AssetTypeAssignmentService.new(self)
    end
end
