require 'spec_helper'

module VCAP::CloudController
  describe Membership do
    let(:user) { User.make }
    let!(:space) { Space.make(organization: organization) }
    let!(:space_whose_org_is_suspended) { Space.make(organization: suspended_organization) }
    let(:organization) { Organization.make }
    let(:suspended_organization) { Organization.make(status: 'suspended') }
    let!(:space_in_some_other_org) { Space.make }

    subject(:membership) { Membership.new(user) }

    describe '#has_any_roles?' do
      it 'returns true for admins' do
        user.update(admin: true)
        result = membership.has_any_roles?('anything')
        expect(result).to be_truthy
      end

      context 'when space roles are provided' do
        before do
          organization.add_user(user)
        end

        describe 'SPACE_DEVELOPER' do
          context 'when the user has the role' do
            before do
              space.add_developer(user)
            end

            it 'returns true' do
              result = membership.has_any_roles?(Membership::SPACE_DEVELOPER, space.guid)
              expect(result).to be_truthy
            end
          end

          context 'when the user does not have the role' do
            before do
              space.remove_developer(user)
            end

            it 'returns false' do
              result = membership.has_any_roles?(Membership::SPACE_DEVELOPER, space.guid)
              expect(result).to be_falsey
            end
          end
        end

        describe 'SPACE_MANAGER' do
          context 'when the user has the role' do
            before do
              space.add_manager(user)
            end

            it 'returns true' do
              result = membership.has_any_roles?(Membership::SPACE_MANAGER, space.guid)
              expect(result).to be_truthy
            end
          end

          context 'when the user does not have the role' do
            before do
              space.remove_manager(user)
            end

            it 'returns false' do
              result = membership.has_any_roles?(Membership::SPACE_MANAGER, space.guid)
              expect(result).to be_falsey
            end
          end
        end

        describe 'SPACE_AUDITOR' do
          context 'when the user has the role' do
            before do
              space.add_auditor(user)
            end

            it 'returns true' do
              result = membership.has_any_roles?(Membership::SPACE_AUDITOR, space.guid)
              expect(result).to be_truthy
            end
          end

          context 'when the user does not have the role' do
            before do
              space.remove_auditor(user)
            end

            it 'returns false' do
              result = membership.has_any_roles?(Membership::SPACE_AUDITOR, space.guid)
              expect(result).to be_falsey
            end
          end
        end

        context 'when the user has any one of multiple requested roles' do
          before do
            space.add_manager(user)
            space.remove_developer(user)
            space.remove_auditor(user)
          end

          it 'returns true' do
            result = membership.has_any_roles?([
              Membership::SPACE_MANAGER,
              Membership::SPACE_DEVELOPER,
              Membership::SPACE_AUDITOR], space.guid)

            expect(result).to be_truthy
          end
        end

        context 'when the user has none of multiple requested roles' do
          before do
            space.remove_manager(user)
            space.remove_developer(user)
            space.remove_auditor(user)
          end

          it 'returns false' do
            result = membership.has_any_roles?([
              Membership::SPACE_MANAGER,
              Membership::SPACE_DEVELOPER,
              Membership::SPACE_AUDITOR], space.guid)

            expect(result).to be_falsey
          end
        end

        context 'when the space_guid is nil' do
          it 'returns false' do
            result = membership.has_any_roles?(Membership::SPACE_DEVELOPER)
            expect(result).to be_falsey
          end
        end

        context 'when the space is in a suspended org and the user has the required role' do
          before do
            space.add_developer(user)
            space.add_manager(user)
            space.add_auditor(user)
            organization.status = 'suspended'
            organization.save
            space.save
          end

          it 'returns false' do
            result = membership.has_any_roles?([
              Membership::SPACE_DEVELOPER,
              Membership::SPACE_MANAGER,
              Membership::SPACE_AUDITOR],
              space.guid)
            expect(result).to be_falsey
          end
        end
      end

      context 'when org roles are provided' do
        before do
          organization.add_user(user)
        end

        describe 'ORG_MEMBER' do
          before do
            organization.add_user(user)
          end

          context 'when the user has the role' do
            before do
              organization.add_user(user)
            end

            it 'returns true' do
              result = membership.has_any_roles?(Membership::ORG_MEMBER, nil, organization.guid)
              expect(result).to be_truthy
            end
          end

          context 'when the user does not have the role' do
            before do
              organization.remove_user(user)
            end

            it 'returns false' do
              result = membership.has_any_roles?(Membership::ORG_MEMBER, nil, organization.guid)
              expect(result).to be_falsey
            end
          end
        end

        describe 'ORG_MANAGER' do
          context 'when the user has the role' do
            before do
              organization.add_manager(user)
            end

            it 'returns true' do
              result = membership.has_any_roles?(Membership::ORG_MANAGER, nil, organization.guid)
              expect(result).to be_truthy
            end
          end

          context 'when the user does not have the role' do
            before do
              organization.remove_manager(user)
            end

            it 'returns false' do
              result = membership.has_any_roles?(Membership::ORG_MANAGER, nil, organization.guid)
              expect(result).to be_falsey
            end
          end
        end

        describe 'ORG_AUDITOR' do
          context 'when the user has the role' do
            before do
              organization.add_auditor(user)
            end

            it 'returns true' do
              result = membership.has_any_roles?(Membership::ORG_AUDITOR, nil, organization.guid)
              expect(result).to be_truthy
            end
          end

          context 'when the user does not have the role' do
            before do
              organization.remove_auditor(user)
            end

            it 'returns false' do
              result = membership.has_any_roles?(Membership::ORG_AUDITOR, nil, organization.guid)
              expect(result).to be_falsey
            end
          end
        end

        describe 'ORG_BILLING_MANAGER' do
          context 'when the user has the role' do
            before do
              organization.add_billing_manager(user)
            end

            it 'returns true' do
              result = membership.has_any_roles?(Membership::ORG_BILLING_MANAGER, nil, organization.guid)
              expect(result).to be_truthy
            end
          end

          context 'when the user does not have the role' do
            before do
              organization.remove_billing_manager(user)
            end

            it 'returns false' do
              result = membership.has_any_roles?(Membership::ORG_BILLING_MANAGER, nil, organization.guid)
              expect(result).to be_falsey
            end
          end
        end

        context 'when the user has any one of multiple requested roles' do
          before do
            organization.add_manager(user)
            organization.remove_billing_manager(user)
            organization.remove_auditor(user)
          end

          it 'returns true' do
            result = membership.has_any_roles?([
              Membership::ORG_MANAGER,
              Membership::ORG_BILLING_MANAGER,
              Membership::ORG_AUDITOR], nil, organization.guid)

            expect(result).to be_truthy
          end
        end

        context 'when the user has none of multiple requested roles' do
          before do
            organization.remove_manager(user)
            organization.remove_billing_manager(user)
            organization.remove_auditor(user)
          end

          it 'returns false' do
            result = membership.has_any_roles?([
              Membership::ORG_MANAGER,
              Membership::ORG_BILLING_MANAGER,
              Membership::ORG_AUDITOR], nil, organization.guid)

            expect(result).to be_falsey
          end
        end

        context 'when the org_guid is nil' do
          before do
            space.add_developer(user)
          end

          it 'returns false' do
            result = membership.has_any_roles?(Membership::ORG_MEMBER, space.guid, nil)
            expect(result).to be_falsey
          end
        end

        context 'when the org is suspended and the user has the required role' do
          before do
            organization.add_user(user)
            organization.add_manager(user)
            organization.add_billing_manager(user)
            organization.add_auditor(user)
            organization.status = 'suspended'
            organization.save
            space.save
          end

          it 'returns false' do
            result = membership.has_any_roles?([
              Membership::ORG_MEMBER,
              Membership::ORG_MANAGER,
              Membership::ORG_AUDITOR,
              Membership::ORG_BILLING_MANAGER],
              nil, organization.guid)
            expect(result).to be_falsey
          end
        end
      end

      context 'when space and org roles are provided' do
        before do
          organization.add_user(user)
        end

        context 'when the user has any one of multiple requested roles' do
          before do
            space.add_manager(user)
            space.remove_developer(user)
            space.remove_auditor(user)
            organization.add_manager(user)
          end

          it 'returns true' do
            result = membership.has_any_roles?([
              Membership::ORG_MANAGER,
              Membership::SPACE_MANAGER,
              Membership::SPACE_DEVELOPER,
              Membership::SPACE_AUDITOR
            ],
              space.guid, organization.guid)

            expect(result).to be_truthy
          end
        end

        context 'when the user has none of multiple requested roles' do
          before do
            space.remove_manager(user)
            space.remove_developer(user)
            space.remove_auditor(user)
            organization.remove_manager(user)
          end

          it 'returns false' do
            result = membership.has_any_roles?([
              Membership::ORG_MANAGER,
              Membership::SPACE_MANAGER,
              Membership::SPACE_DEVELOPER,
              Membership::SPACE_AUDITOR
            ],
              space.guid, organization.guid)

            expect(result).to be_falsey
          end
        end
      end
    end

    describe '#space_guids' do
      context 'user is an admin' do
        it 'returns all spaces' do
          user.update(admin: true)

          result = membership.space_guids

          expect(result).to include(space.guid, space_whose_org_is_suspended.guid, space_that_user_doesnt_develop_in.guid, space_in_some_other_org.guid)
        end
      end

      context 'user is not an admin' do
        let(:result) { nil }

        before do
          result = membership.space_guids
        end

        it 'returns all spaces belonging to the user' do
          expect(result).to include(space.guid, space_that_user_manages.guid)
          expect(result).to_not include(space_in_some_other_org.guid)
        end

        it 'returns all spaces in suspended organizations' do
          expect(result).to include(space_whose_org_is_suspended.guid)
        end

        it 'returns all spaces belonging to each org the user manages' do
          expect(result).to include(space.guid, space_whose_org_is_suspended.guid, space_that_user_doesnt_develop_in.guid)
          expect(result).to_not include(space_in_some_other_org.guid)
        end

        context 'space developers' do
          before do
            let(:user) { make_developer_for_space(space) }
          end

          it 'returns all spaces in which the user develops' do
            expect(result).to include(space.guid)
          end
        end

        context 'space managers' do
          before do
            let(:user) { make_manager_for_space(space) }
          end

          it 'returns all spaces that the user audits' do
            expect(result).to include(space.guid)
          end
        end

        context 'space auditors' do
          before do
            let(:user) { make_auditor_for_space(space) }
          end

          it 'returns all spaces in which the user manages' do
            expect(result).to include(space.guid)
          end
        end
      end
    end
  end
end
