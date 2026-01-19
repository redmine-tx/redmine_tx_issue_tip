class ReportController < ApplicationController
  include QueriesHelper
  include IssuesHelper
  helper :queries
  helper :issues
  helper :sc_report

  layout 'base'
  before_action :find_project
  before_action :authorize

  def index
  end

#  def mypage
#  end

  def status
  end

  def validate
  end

#  def manager
#  end

  def update_page
    @user = params[:user_id] ? User.find(params[:user_id]) : User.current
    @project = Project.find(params[:project_id])
    
    # 정렬 설정 저장 (선택사항)
    # 현재는 세션이나 사용자 설정에 저장하지 않고 즉시 처리
    
    @updated_blocks = ['my-issues']
    
    respond_to do |format|
      format.js
    end
  end

  private

  def find_project
    @user = params[:user_id] ? User.find(params[:user_id]) : User.current
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def authorize
    raise Unauthorized unless User.current.allowed_to?(:view_sc_report, @project)
  end
end
