require_relative "base"

module OpenProject::Webhooks::EventResources
  class WorkPackage < Base
    class << self
      def notification_names
        [
          OpenProject::Events::AGGREGATED_WORK_PACKAGE_JOURNAL_READY
        ]
      end

      def available_actions
        %i(updated created comment internal_comment)
      end

      def resource_name
        I18n.t :label_work_package_plural
      end

      protected

      def handle_notification(payload, event_name)
        journal = payload[:journal]
        action = 'created'
        unless journal.initial?
          if journal.note.present?
            if journal.internal
              action = 'internal_comment'
            else
              action = 'comment'
            end
          else
            action = 'updated'
          end
        end
        event_name = prefixed_event_name(action)
        work_package = journal.journable
        active_webhooks.with_event_name(event_name).pluck(:id).each do |id|
          if %w[created updated].include? action
              WorkPackageWebhookJob.perform_later(id, work_package, event_name)
            elsif %w[comment internal_comment].include? action
              WorkPackageCommentWebhookJob.perform_later(id, journal, event_name)
            end
          end
        end
    end
  end
end
