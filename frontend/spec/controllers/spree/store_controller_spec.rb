require 'spec_helper'

class StorefrontFakesController < Spree::StoreController
  def index
    render plain: 'index'
  end
end

describe Spree::StoreController, type: :controller do
  describe '#store_etag' do
    let!(:store) { create(:store, default: true, default_locale: 'es', default_currency: 'EUR') }

    before { controller.send(:set_locale) }
    after { I18n.locale = I18n.default_locale }

    context 'guest visitor' do
      it do
        expect(controller.send(:store_etag)).to eq [
          store,
          'EUR',
          :es,
          false
        ]
      end
    end

    context 'with signed in user' do
      let(:user) { stub_model(Spree::LegacyUser) }

      before do
        allow(controller).to receive_messages try_spree_current_user: user
        allow(controller).to receive_messages spree_current_user: user
      end

      context 'regular user' do
        it do
          expect(controller.send(:store_etag)).to eq [
            store,
            'EUR',
            :es,
            true,
            false
          ]
        end
      end

      context 'admin user' do
        before { user.spree_roles << Spree::Role.find_or_create_by(name: :admin) }

        it do
          expect(controller.send(:store_etag)).to eq [
            store,
            'EUR',
            :es,
            true,
            true
          ]
        end
      end
    end
  end

  describe '#redirect_unauthorized_access' do
    controller(StorefrontFakesController) do
      def index
        redirect_unauthorized_access
      end
    end
    context 'when logged in' do
      before do
        allow(controller).to receive_messages(try_spree_current_user: double('User', id: 1, last_incomplete_spree_order: nil))
      end

      it 'redirects forbidden path' do
        get :index
        expect(response).to redirect_to('/forbidden')
      end
    end

    context 'when guest user' do
      before do
        allow(controller).to receive_messages(try_spree_current_user: nil)
      end

      it 'redirects login path' do
        allow(controller).to receive_messages(spree_login_path: '/login')
        get :index
        expect(response).to redirect_to('/login')
      end

      it 'redirects root path' do
        get :index
        expect(response).to redirect_to('/')
      end
    end
  end
end
