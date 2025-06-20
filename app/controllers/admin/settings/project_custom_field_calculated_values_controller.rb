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

module Admin::Settings
  class ProjectCustomFieldCalculatedValuesController < ::Admin::SettingsController
    include CustomFields::SharedActions
    include OpTurbo::ComponentStream
    include FlashMessagesOutputSafetyHelper
    include Admin::Settings::ProjectCustomFields::ComponentStreams

    before_action :check_feature_flag

    menu_item :project_custom_fields_settings

    def show
      # quick fixing redirect issue from perform_update
      # perform_update is always redirecting to the show action although configured otherwise
      render :edit
    end

    def new
      @custom_field = ProjectCustomField.new(custom_field_section_id: params[:custom_field_section_id],
                                             field_format: "calculated_value")

      respond_to :html
    end

    def edit
      @custom_field = ProjectCustomField.find_by(id: params[:id], field_format: "calculated_value")
    end

    private

    def check_feature_flag
      render_404 unless OpenProject::FeatureDecisions.calculated_value_project_attribute_active?
    end
  end
end
