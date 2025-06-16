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

module Admin::CustomFields::CalculatedValues
  class DetailsForm < ApplicationForm
    form do |details_form|
      details_form.text_field(
        name: :name,
        label: I18n.t(:label_name),
        required: true
      )

      details_form.select_list(
        name: :custom_field_section_id,
        label: I18n.t("activerecord.attributes.project_custom_field.custom_field_section"),
        required: true
      ) do |li|
        ProjectCustomFieldSection.all.collect.each do |cs|
          li.option(value: cs.id, label: cs.name)
        end
      end

      details_form.text_field(
        name: :formula,
        label: I18n.t(:label_formula),
        required: true,
        caption: I18n.t("custom_fields.instructions.formula")
      )

      details_form.check_box(
        name: :is_for_all,
        label: I18n.t("activerecord.attributes.custom_field.is_for_all"),
        caption: I18n.t("custom_fields.instructions.is_for_all")
      )

      details_form.check_box(
        name: :admin_only,
        label: I18n.t("activerecord.attributes.custom_field.admin_only"),
        caption: I18n.t("custom_fields.instructions.admin_only")
      )

      details_form.hidden(name: :field_format)
      details_form.hidden(name: :type, scope_name_to_model: false)

      details_form.submit(name: :submit, label: I18n.t(:button_save), scheme: :default)
    end
  end
end
