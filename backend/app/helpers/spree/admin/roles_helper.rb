# frozen_string_literal: true

module Spree
  module Admin
    module RolesHelper
      # @label rbac.roles.update
      def set_roles
        if user_params[:spree_role_ids]
          @user.spree_roles = Spree::Role.accessible_by(current_ability).where(id: user_params[:spree_role_ids])
        end
      end
    end
  end
end
