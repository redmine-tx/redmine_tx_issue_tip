require_dependency 'my_controller'

Redmine::Plugin.register :redmine_tx_issue_tip do
  name 'Issue Tip plugin'
  author 'KiHyun Kang'
  description '일감에 조치사항과 추가 개선을 적용합니다.'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'testors@gmail.com'

  requires_redmine_plugin :redmine_tx_0_base, :version_or_higher => '0.0.1'

  settings default: { 'no_tip_for_bugs' => true }, partial: 'settings/tx_issue_tip_setting'
end

Rails.application.config.after_initialize do

  require_dependency File.expand_path('../lib/tx_issue_patch', __FILE__)
  require_dependency File.expand_path('../lib/tx_issue_tip_query_patch', __FILE__)

end

