require_dependency 'my_controller'

Redmine::Plugin.register :redmine_tx_issue_tip do
  name 'Issue Tip plugin'
  author 'KiHyun Kang'
  description '일감에 조치사항과 추가 개선을 적용합니다.'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'testors@gmail.com'

  requires_redmine_plugin :redmine_tx_0_base, :version_or_higher => '0.0.1'

  settings default: {
    'no_tip_for_bugs' => true,
    'disable_need_to_start' => false,
    'disable_precedence_completed' => false,
    'disable_due_date_overdue' => false,
    'disable_due_date_today' => false,
    'disable_different_version' => false,
    'disable_no_due_date' => false,
    'disable_due_date_soon' => false
  }, partial: 'settings/tx_issue_tip_setting'
end

Rails.application.config.after_initialize do

  require_dependency File.expand_path('../lib/tx_issue_patch', __FILE__)
  require_dependency File.expand_path('../lib/tx_issue_tip_query_patch', __FILE__)

  # IssueQuery에 커스텀 컬럼 추가
  IssueQuery.available_columns += [
    ScReportHelper::CustomQueryColumn.new(:tip,
      :caption => :field_tip,
      :sortable => "tip"
    ),
    ScReportHelper::CustomQueryColumn.new(:fixed_version_plus,
      :caption => :field_fixed_version_plus,
      :sortable => "#{Version.table_name}.effective_date"
    ),
    ScReportHelper::CustomQueryColumn.new(:estimated_hours_plus,
      :caption => :field_estimated_hours_plus,
      :sortable => "estimated_hours"
    )
  ]


end

