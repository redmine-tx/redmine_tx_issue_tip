require_dependency 'issue_query'

module TxIssueTipQueryPatch
  def self.included(base)
    base.class_eval do
      extend TxBaseHelper::IssueQueryColumnHelper
      include TxBaseHelper::IssueQueryColumnHelper

      # 가상 컬럼 추가
      add_issue_virtual_column :tip,
        value_proc: ->(issue) { issue.tip },
        caption: :field_tip,
        sortable: "tip"

      add_issue_virtual_column :fixed_version_plus,
        value_proc: ->(issue) { issue.fixed_version_plus },
        caption: :field_fixed_version_plus,
        sortable: "#{Version.table_name}.effective_date"

      add_issue_virtual_column :estimated_hours_plus,
        value_proc: ->(issue) { issue.estimated_hours_plus },
        caption: :field_estimated_hours_plus,
        sortable: "estimated_hours"

      # Override the initialize_available_filters method
      alias_method :initialize_available_filters_without_tx_issue_tip, :initialize_available_filters
      alias_method :initialize_available_filters, :initialize_available_filters_with_tx_issue_tip

      # Override the issues method to filter by tip
      alias_method :issues_without_tx_issue_tip, :issues
      alias_method :issues, :issues_with_tx_issue_tip
    end
  end

  def initialize_available_filters_with_tx_issue_tip
    initialize_available_filters_without_tx_issue_tip

    # Add tip filter as a text filter
    add_issue_filter "tip",
      type: :text,
      name: l(:field_tip)
  end
  
  # SQL 쿼리에서는 tip 필터를 무시 (DB 컬럼이 아니므로)
  def sql_for_tip_field(field, operator, value)
    # 빈 조건을 반환하여 SQL 쿼리에서 제외
    "1=1"
  end
  
  # issues 메서드를 오버라이드하여 Ruby 레벨에서 필터링
  def issues_with_tx_issue_tip(options={})
    issues = issues_without_tx_issue_tip(options)
    
    # tip 필터가 있는 경우에만 처리
    if has_filter?("tip")
      operator = operator_for("tip")
      values = values_for("tip")
      
      issues = issues.select do |issue|
        tip_value = issue.tip.to_s
        
        case operator
        when "~"  # contains
          values.any? { |v| tip_value.include?(v) }
        when "!~" # doesn't contain
          values.none? { |v| tip_value.include?(v) }
        when "^"  # starts with
          values.any? { |v| tip_value.start_with?(v) }
        when "$"  # ends with
          values.any? { |v| tip_value.end_with?(v) }
        when "="  # is
          values.any? { |v| tip_value == v }
        when "!"  # is not
          values.none? { |v| tip_value == v }
        when "!*" # none (empty)
          tip_value.blank?
        when "*"  # any (not empty)
          tip_value.present?
        else
          true
        end
      end
    end
    
    issues
  end
end

# Apply the patch
unless IssueQuery.included_modules.include?(TxIssueTipQueryPatch)
  IssueQuery.send(:include, TxIssueTipQueryPatch)
end
