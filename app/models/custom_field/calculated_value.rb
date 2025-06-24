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

# Methods for custom fields with a format of "calculated value".
# Should be included in the CustomField model.
module CustomField::CalculatedValue
  def validate_formula
    return unless field_format_calculated_value?

    # List of allowed characters in a formula. This only performs a very basic validation.
    # Allowed characters are:
    # + - / * ( ) whitespace digits and decimal points
    # Additionally, the formula may contain references to custom fields in the form of `cf_123` where 123 is the ID of
    # the custom field.
    # Once this basic validation passes, the formula will be parsed and validated by Dentaku, which builds an AST
    # and ensures that the formula is really valid. A welcome side effect of the basic validation done here is that
    # it prevents built-in functions from being used in the formula, which we do not want to allow.
    allowed_chars = %w[+ - / * ( )] + [" "]
    split_pattern = /\s|(\+)|(-)|(\*)|(\()|(\))/
    pattern = /^(cf_\d+|\d+\.?\d*|\.\d+.|[#{allowed_chars.join}]+)$/
    valid_formula_string = formula_string.split(split_pattern).reject(&:empty?).all? do |token|
      token.match?(pattern)
    end

    errors.add(:formula, :invalid) unless valid_formula_string

    # WP-64348: check for valid (i.e., visible & enabled) custom field references (see #cf_ids_used_in_formula)

    # Dentaku will return nil if the formula is invalid.
    # TODO WP-64348: add support for referenced custom fields by injecting them as variables,
    #       e.g. Dentaku(formula_string, cf_123: CustomField.find(123).value)
    errors.add(:formula, :invalid) unless Dentaku(formula_string)
  end

  def formula=(value)
    if value.is_a?(String)
      super({ formula: value, referenced_custom_fields: cf_ids_used_in_formula })
    else
      super
    end
  end

  def formula_string
    formula.is_a?(Hash) ? formula["formula"] : formula
  end

  private

  # Returns a list of custom field IDs used in the formula.
  # For a formula like `2 + cf_12 + cf_4` it returns `[12, 4]`.
  def cf_ids_used_in_formula
    (formula_string || "").scan(/cf_(\d+)/).flatten.map(&:to_i)
  end
end
