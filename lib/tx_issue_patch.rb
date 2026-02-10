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
      return "시작 필요"
      when :precedence_completed
      return "선행 일감 완료됨"
      when :due_date_overdue
      return "#{(Date.today - self.due_date).to_i}일 지연"
      when :due_date_today
      return "오늘 마감"
      when :different_version
      return "목표버전 불일치"
      when :no_due_date
      return "완료일정 기입 필요"
      when :due_date_soon
      return "마감 임박"
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

        # 선행일감 완료된 경우
        if self.start_date == nil && self.relations.any? { |r| r.relation_type == 'blocks' && r.issue_to_id == self.id && IssueStatus.is_implemented?(r.issue_from.status_id) } then
          return :precedence_completed
        end

        # 시작일이 오늘 이전이면 시작 필요
        if self.start_date && self.start_date <= Date.today then
          return :need_to_start
        end
      end

      if self.due_date
        if (self.due_date - Date.today).to_i < 0
          return :due_date_overdue
        elsif (self.due_date - Date.today).to_i ==  0
          return :due_date_today
        elsif (self.due_date - Date.today).to_i <= 1
          return :due_date_soon
        end
        return nil
      end

      if self.fixed_version_id && self.parent_issue_id && self.parent_issue && self.parent_issue.fixed_version_id != self.fixed_version_id then
        return :different_version
      end

      return nil if Setting[:plugin_redmine_tx_issue_tip][:no_tip_for_bugs] && Tracker.is_bug?(self.tracker_id)

      if self.fixed_version && self.fixed_version.effective_date && self.fixed_version.effective_date < Date.today + 3.months then
        return :no_due_date
      end

      nil
    end
    
  end
end

unless Issue.included_modules.include?(TxIssuePatch)
  Issue.send(:include, TxIssuePatch)
end
