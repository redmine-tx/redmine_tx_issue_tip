module ScReportHelper
  def render_issues(title, project, issues, columns, options = {})
    return if issues.empty?

    s = +''
    s << content_tag('h3', title) if title.present?
    
    # form_tag로 감싸고 data-cm-url 속성 추가
    s << form_tag({}, :data => {:cm_url => issues_context_menu_path}) do
      # 편집 후 돌아올 페이지 설정
      hidden_field_tag('back_url', url_for(:params => request.query_parameters), :id => nil) +
      content_tag('div', :class => 'autoscroll') do
        content_tag('table', :class => 'list issues odd-even') do
          # 헤더
          header = content_tag('thead') do
            content_tag('tr') do
              content_tag('th', check_box_tag('check_all', '', false, :class => 'toggle-selection'), :class => 'checkbox hide-when-print') +
              columns.map { |column| content_tag('th', l("field_#{column}")) }.join.html_safe +
              content_tag('th', '', :class => 'buttons')
            end
          end
          
          # 본문
          body = content_tag('tbody') do
            issues.map do |issue|
              content_tag('tr', :id => "issue-#{issue.id}", :class => "hascontextmenu #{cycle('odd', 'even')} #{issue.css_classes}") do
                content_tag('td', check_box_tag("ids[]", issue.id, false, :id => nil), :class => 'checkbox hide-when-print') +
                columns.map do |column_name|
                  # 심볼을 QueryColumn 객체로 변환
                  column_obj = if column_name.is_a?(Symbol)
                    IssueQuery.available_columns.find { |col| col.name == column_name }
                  else
                    column_name
                  end
                  
                  content_tag('td', column_content(column_obj, issue), :class => column_name)
                end.join.html_safe +
                content_tag('td', link_to_context_menu, :class => 'buttons')
              end
            end.join.html_safe
          end
          
          header + body
        end
      end
    end
    
    s.html_safe
  end

=begin
  def get_version_color(version)
    return '#999999' unless version
    return '#999999' unless version.effective_date

    today = Date.today
    if version.effective_date < today
      '#ff0000'  # 지난 버전
    elsif version.effective_date <= today + 7.days
      '#ff9900'  # 1주일 이내
    elsif version.effective_date <= today + 30.days
      '#ffff00'  # 1개월 이내
    else
      '#00ff00'  # 1개월 이상
    end
  end
=end

  class CustomQueryColumn < QueryColumn
    def initialize(name, options={})
      super(name, options)
    end

    def value(issue)
      # 여기서 컬럼에 표시할 값을 계산
      case name
      when :tip
        issue.tip
      when :fixed_version_plus
        issue.fixed_version_plus
      end
    end
  end

  def build_issue_query(name, project, column_names = nil)
    query = IssueQuery.new(name: name)
    query.project = project
    query.column_names = column_names || [:id, :tip, :status, :priority, :subject, :assigned_to, :fixed_version_plus, :done_ratio, :due_date]
    
    if params[:sort].present?
      query.sort_criteria = params[:sort]
    end
    
    query
  end
  
  def sort_my_issues(issues, query, params)
    # 정렬 파라미터 처리
    if params[:settings] && params[:settings]['my-issues'] && params[:settings]['my-issues'][:sort]
      sort_init = params[:settings]['my-issues'][:sort].split(',')
      query.sort_criteria = sort_init.map { |s| s.split(':') }
    end
    
    # 이미 필터링된 my_issues를 사용하여 정렬
    sorted_issues = issues.sort_by do |issue|
      key = query.sort_criteria_key(0)
      if key
        value = key.to_s.split('.').inject(issue) { |obj, method| obj.send(method) rescue nil }
        # nil 값 처리 - nil은 항상 마지막으로
        if value.nil?
          [1, issue.id]  # nil 값은 두 번째 정렬 기준으로 id 사용
        else
          [0, value]
        end
      else
        [0, issue.id]
      end
    end
    
    if query.sort_criteria.first && query.sort_criteria.first[1] == 'desc'
      sorted_issues.reverse!
    end
    
    sorted_issues
  end
  
  def render_sortable_issue_list(issues, query, block_id, project = nil)
    content_tag('div', :id => block_id) do
      form_tag({}, :data => {:cm_url => issues_context_menu_path}) do
        hidden_field_tag('back_url', url_for(:params => request.query_parameters), :id => nil) +
        content_tag('div', :class => 'autoscroll') do
          content_tag('table', :class => 'list issues odd-even') do
            # 헤더
            header = content_tag('thead') do
              content_tag('tr') do
                content_tag('th', check_box_tag('check_all', '', false, :class => 'toggle-selection'), :class => 'checkbox hide-when-print') +
                query.inline_columns.map do |column|
                  if column.sortable?
                    css, order = nil, column.default_order
                    if column.name.to_s == query.sort_criteria.first_key
                      if query.sort_criteria.first_asc?
                        css = 'sort asc icon icon-sorted-desc'
                        order = 'desc'
                      else
                        css = 'sort desc icon icon-sorted-asc'
                        order = 'asc'
                      end
                    end
                    
                    sort_param = query.sort_criteria.add(column.name, order).to_param
                    link_options = {
                      :title => l(:label_sort_by, "\"#{column.caption}\""),
                      :class => css,
                      :remote => true,
                      :method => :post,
                      :data => {:params => {:settings => {'my-issues' => {:sort => sort_param}}}.to_param}
                    }
                    
                    # 프로젝트가 있는 경우와 없는 경우를 구분
                    if project
                      url = {:controller => 'report', :action => 'update_page', :project_id => project}
                      link_options[:data][:params] = {:settings => {'my-issues' => {:sort => sort_param}}, :project_id => project.id}.to_param
                    else
                      url = {:controller => 'my', :action => 'update_page_sc_report'}
                    end
                    
                    content_tag('th', :class => column.css_classes) do
                      link_to(column.caption, url, link_options)
                    end
                  else
                    content_tag('th', column.caption, :class => column.css_classes)
                  end
                end.join.html_safe +
                content_tag('th', '', :class => 'buttons')
              end
            end
            
            # 본문
            body = content_tag('tbody') do
              issues.map do |issue|
                content_tag('tr', :id => "issue-#{issue.id}", :class => "hascontextmenu #{cycle('odd', 'even')} #{issue.css_classes}") do
                  content_tag('td', check_box_tag("ids[]", issue.id, false, :id => nil), :class => 'checkbox hide-when-print') +
                  query.inline_columns.map do |column|
                    content_tag('td', column_content(column, issue), :class => column.css_classes)
                  end.join.html_safe +
                  content_tag('td', link_to_context_menu, :class => 'buttons')
                end
              end.join.html_safe
            end
            
            header + body
          end
        end
      end
    end
  end
end 