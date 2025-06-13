# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Admin
  class ScimClientsController < ::ApplicationController
    include OpTurbo::ComponentStream

    before_action :require_admin

    menu_item :scim_clients

    layout "admin"

    def index
      @scim_clients = ScimClient.all
    end

    def new
      @scim_client = ScimClient.new(authentication_method: :oauth2_token)
    end

    def edit
      @scim_client = ScimClient.find(params[:id])

      first_time_setup(@scim_client)
    end

    def create
      result = ::ScimClients::CreateService.new(user: User.current).call(scim_client_params)
      result.on_failure do
        @scim_client = result.result
        update_via_turbo_stream(component: Admin::ScimClients::FormComponent.new(@scim_client))
        respond_with_turbo_streams do |format|
          format.html { render :new }
        end
      end

      result.on_success do
        flash[:notice] = t(:notice_successful_create)
        redirect_to edit_admin_scim_client_path(result.result, first_time_setup: true)
      end
    end

    def update
      @scim_client = ScimClient.find(params[:id])
      result = ::ScimClients::UpdateService.new(user: User.current, model: @scim_client).call(scim_client_params)

      result.on_failure do
        update_via_turbo_stream(component: Admin::ScimClients::FormComponent.new(@scim_client))
        respond_with_turbo_streams do |format|
          format.html { render :edit }
        end
      end

      result.on_success do
        flash[:notice] = t(:notice_successful_update)
        redirect_to action: :index
      end
    end

    def deletion_dialog
      respond_with_dialog ScimClients::DeleteScimClientDialogComponent.new(ScimClient.find(params[:id]))
    end

    def destroy
      model = ScimClient.find(params[:id])
      result = ::ScimClients::DeleteService.new(user: User.current, model:).call

      if result.success?
        flash[:notice] = I18n.t(:notice_successful_delete)
      else
        flash[:error] = result.errors.full_messages
      end

      redirect_to action: :index
    end

    private

    def scim_client_params
      params.require(:scim_client).permit(:name, :auth_provider_id, :authentication_method, :jwt_sub)
    end

    def first_time_setup(scim_client)
      return if params[:first_time_setup].blank?

      case scim_client.authentication_method
      when "oauth2_token"
        if scim_client.access_tokens.empty?
          ::ScimClients::GenerateStaticTokenService.new(scim_client).call
          @setup_token = true
        end
      when "oauth2_client"
        # Ensuring that the client secret can't infinitely be accessed by calling with ?first_time_setup=true long after
        # the initial setup (there is no other persisted marker showing us, that this is the first time)
        if scim_client.oauth_application.created_at > 1.minute.ago
          @setup_client_credentials = true
        end
      end
    end
  end
end
