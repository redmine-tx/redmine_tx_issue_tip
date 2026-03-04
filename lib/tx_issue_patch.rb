require_dependency 'issue'

module TxIssuePatch
  def self.included(base)
    base.class_eval do
      include InstanceMethods
    end
  end
  
  module InstanceMethods
    def tip
      tag = self.guide_tag

      case tag
      when nil
        return nil
      when :need_to_start
        return I18n.t('tip_need_to_start')
      when :blocker_resolved
        return I18n.t('tip_precedence_completed')
      when :overdue
        return I18n.t('tip_due_date_overdue', days: (Date.today - self.due_date).to_i)
      when :due_today
        return I18n.t('tip_due_date_today')
      when :version_mismatch
        return I18n.t('tip_different_version')
      when :due_date_needed
        return I18n.t('tip_no_due_date')
      when :due_tomorrow
        return I18n.t('tip_due_date_soon')
      else
        return tag.to_s
      end
    end

    def guide_tag
      if IssueStatus.is_implemented?(self.status_id)
        return nil
      end

      if IssueStatus.is_discarded?(self.status_id)
        return nil
      end

      if IssueStatus.is_postponed?(self.status_id)
        return nil
      end

      # 아직 시작 상태가 아닌경우
      if !IssueStatus.is_in_progress?(self.status_id) then

        # 선행일감(blocker)이 완료된 경우
        if self.start_date == nil && self.relations.any? { |r| r.relation_type == 'blocks' && r.issue_to_id == self.id && IssueStatus.is_implemented?(r.issue_from.status_id) } then
          return :blocker_resolved
        end

        # 시작일이 오늘 이전이면 시작 필요
        if self.start_date && self.start_date <= Date.today then
          return :need_to_start
        end
      end

      if self.due_date
        if (self.due_date - Date.today).to_i < 0
          return :overdue
        elsif (self.due_date - Date.today).to_i == 0
          return :due_today
        elsif (self.due_date - Date.today).to_i <= 1
          return :due_tomorrow
        end
        return nil
      end

      if self.fixed_version_id && self.parent_issue_id && self.parent_issue && self.parent_issue.fixed_version_id != self.fixed_version_id then
        return :version_mismatch
      end

      return nil if Setting[:plugin_redmine_tx_issue_tip][:no_tip_for_bugs] && Tracker.is_bug?(self.tracker_id)

      if self.fixed_version && self.fixed_version.effective_date && self.fixed_version.effective_date < Date.today + 3.months then
        return :due_date_needed
      end

      nil
    end
    
  end
end

unless Issue.included_modules.include?(TxIssuePatch)
  Issue.send(:include, TxIssuePatch)
end
