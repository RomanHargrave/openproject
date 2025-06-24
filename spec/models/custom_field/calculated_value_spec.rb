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

require "spec_helper"

RSpec.describe CustomField::CalculatedValue, with_flag: { calculated_value_project_attribute: true } do
  context "when calculated value" do
    subject(:custom_field) { create(:calculated_value_project_custom_field) }

    describe "#formula=" do
      it "splits formula and referenced custom fields on persist if given a string" do
        formula = "1 * cf_7 + cf_42"
        subject.formula = formula

        expect(subject.formula).to eq({ "formula" => formula, "referenced_custom_fields" => [7, 42] })
      end

      it "omits referenced custom fields if none are given" do
        formula = "2 + 3 * (8 / 7)"
        subject.formula = formula

        expect(subject.formula).to eq({ "formula" => formula, "referenced_custom_fields" => [] })
      end
    end

    describe "#formula_string" do
      it "returns an empty string if no formula is set" do
        expect(subject.formula_string).to eq("")
      end

      it "returns the formula as a string" do
        formula = "1 * cf_7 + cf_42"
        subject.formula = formula

        expect(subject.formula_string).to eq(formula)
      end
    end

    describe "#validate_formula" do
      let(:formula) { "" }

      before do
        subject.formula = formula
        subject.validate_formula
      end

      context "with an empty formula" do
        it "is valid" do
          expect(subject).to be_valid
        end
      end

      context "with a formula containing only allowed characters" do
        let(:formula) { "1 / 2 + (3 * 4.5) - 0.0" }

        it "is valid" do
          expect(subject).to be_valid
        end
      end

      context "with a formula containing forbidden characters" do
        let(:formula) { "abc + 2" }

        it "is invalid" do
          expect(subject).not_to be_valid
          expect(subject.errors[:formula]).to include("is invalid.")
        end
      end

      context "with a formula that is not a valid equation" do
        let(:formula) { "1 / + - 3" }

        it "is invalid" do
          expect(subject).not_to be_valid
          expect(subject.errors[:formula]).to include("is invalid.")
        end
      end

      context "with a formula that causes a division by zero error" do
        let(:formula) { "1 / 0" }

        it "is invalid" do
          expect(subject).not_to be_valid
          expect(subject.errors[:formula]).to include("is invalid.")
        end
      end
    end
  end
end
