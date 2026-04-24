# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Sensors', type: :request do
  let_it_be(:admin)   { create(:user, :admin, locale: 'en') }
  let_it_be(:regular) { create(:user, admin: false, locale: 'en') }

  let(:unauthorized_message) { I18n.t('controllers.admin.unauthorized', locale: regular.locale) }

  shared_examples 'redirects to sign in' do
    it { expect(response).to redirect_to(new_session_path) }
  end

  shared_examples 'denies non-admin' do
    it 'redirects to root with an alert' do
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(unauthorized_message)
    end
  end

  describe 'GET /admin/sensors' do
    context 'when not authenticated' do
      before { get admin_sensors_path }

      include_examples 'redirects to sign in'
    end

    context 'when signed in as a non-admin' do
      before { sign_in_as(regular) && get(admin_sensors_path) }

      include_examples 'denies non-admin'
    end

    context 'when signed in as an admin' do
      let!(:listed_sensor) { create(:sensor, :with_valid_keys) }

      before { sign_in_as(admin) && get(admin_sensors_path) }

      it 'returns ok and renders the index' do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t('admin.sensors.index.title'))
        expect(response.body).to include('data-controller="admin-sensors-modals"')
        expect(response.body).to include('id="admin-shared-qr-sticker"')
        expect(response.body).to include(qr_sticker_preview_admin_sensor_path(listed_sensor))
      end
    end
  end

  describe 'GET /admin/sensors/new' do
    context 'when not authenticated' do
      before { get new_admin_sensor_path }

      include_examples 'redirects to sign in'
    end

    context 'when signed in as a non-admin' do
      before { sign_in_as(regular) && get(new_admin_sensor_path) }

      include_examples 'denies non-admin'
    end

    context 'when signed in as an admin' do
      before { sign_in_as(admin) && get(new_admin_sensor_path) }

      it 'returns ok and renders the new form' do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t('admin.sensors.new.title'))
      end
    end
  end

  describe 'POST /admin/sensors' do
    context 'when not authenticated' do
      before { post admin_sensors_path }

      include_examples 'redirects to sign in'
    end

    context 'when signed in as a non-admin' do
      before { sign_in_as(regular) && post(admin_sensors_path) }

      include_examples 'denies non-admin'
    end

    context 'when signed in as an admin' do
      before { sign_in_as(admin) }

      it 'creates an unpaired sensor and redirects to the index' do
        expect { post admin_sensors_path }.to change(Sensor, :count).by(1)

        expect(response).to redirect_to(admin_sensors_path)
        expect(flash[:notice]).to eq(
          I18n.t('admin.sensors.create.created', uid: Sensor.order(:created_at).last.uid)
        )
      end
    end
  end

  describe 'DELETE /admin/sensors/:id' do
    let_it_be(:sensor) { create(:sensor, :with_valid_keys) }
    let(:unknown_id) { '00000000-0000-0000-0000-000000000001' }

    context 'when not authenticated' do
      before { delete admin_sensor_path(sensor) }

      include_examples 'redirects to sign in'
    end

    context 'when signed in as a non-admin' do
      before { sign_in_as(regular) && delete(admin_sensor_path(sensor)) }

      include_examples 'denies non-admin'
    end

    context 'when signed in as an admin' do
      before { sign_in_as(admin) }
      let(:uid) { sensor.uid }

      it 'destroys the sensor and redirects with a notice' do
        expect { delete admin_sensor_path(sensor) }.to change(Sensor, :count).by(-1)

        expect(response).to redirect_to(admin_sensors_path)
        expect(flash[:notice]).to eq(I18n.t('admin.sensors.destroy.notice', uid:))
      end

      it 'returns not found for an unknown id' do
        delete admin_sensor_path(unknown_id)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET /admin/sensors/:id/qr_sticker' do
    let_it_be(:sticker_sensor) { create(:sensor, :with_valid_keys) }

    context 'when not authenticated' do
      before { get qr_sticker_admin_sensor_path(sticker_sensor) }

      include_examples 'redirects to sign in'
    end

    context 'when signed in as a non-admin' do
      before { sign_in_as(regular) && get(qr_sticker_admin_sensor_path(sticker_sensor)) }

      include_examples 'denies non-admin'
    end

    context 'when signed in as an admin' do
      let(:unknown_id) { '00000000-0000-0000-0000-000000000001' }

      it 'returns a PNG for thermal / label printing' do
        sign_in_as(admin)
        get qr_sticker_admin_sensor_path(sticker_sensor, format: :png)

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to start_with('image/png')
        expect(response.headers['Content-Disposition'].to_s).to include('attachment')
        expect(response.body.byteslice(0, 4)).to eq("\x89PNG".b)
      end

      it 'returns not found for an unknown id' do
        sign_in_as(admin)
        get qr_sticker_admin_sensor_path(unknown_id, format: :png)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET /admin/sensors/:id/qr_sticker_preview' do
    let_it_be(:preview_sensor) { create(:sensor, :with_valid_keys) }
    let(:unknown_id) { '00000000-0000-0000-0000-000000000001' }

    context 'when not authenticated' do
      it 'redirects to sign in' do
        get qr_sticker_preview_admin_sensor_path(preview_sensor)
        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when signed in as a non-admin' do
      it 'denies' do
        sign_in_as(regular)
        get qr_sticker_preview_admin_sensor_path(preview_sensor)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(unauthorized_message)
      end
    end

    context 'when signed in as an admin' do
      it 'returns the modal content fragment' do
        sign_in_as(admin)
        get qr_sticker_preview_admin_sensor_path(preview_sensor), headers: { 'Accept' => 'text/html' }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('admin-shared-qr-sticker')
        expect(response.body).to include(preview_sensor.uid)
      end

      it 'returns not found for an unknown id' do
        sign_in_as(admin)
        get qr_sticker_preview_admin_sensor_path(unknown_id)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET /admin/sensors/:id/destroy_confirmation' do
    let_it_be(:to_destroy_sensor) { create(:sensor, :with_valid_keys) }
    let(:unknown_id) { '00000000-0000-0000-0000-000000000001' }

    context 'when not authenticated' do
      it 'redirects to sign in' do
        get destroy_confirmation_admin_sensor_path(to_destroy_sensor)
        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when signed in as a non-admin' do
      it 'denies' do
        sign_in_as(regular)
        get destroy_confirmation_admin_sensor_path(to_destroy_sensor)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(unauthorized_message)
      end
    end

    context 'when signed in as an admin' do
      it 'returns the delete confirmation fragment' do
        sign_in_as(admin)
        get destroy_confirmation_admin_sensor_path(to_destroy_sensor), headers: { 'Accept' => 'text/html' }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('admin-shared-destroy-sensor')
        expect(response.body).to include(to_destroy_sensor.uid)
        expect(response.body).to include(admin_sensor_path(to_destroy_sensor))
      end

      it 'returns not found for an unknown id' do
        sign_in_as(admin)
        get destroy_confirmation_admin_sensor_path(unknown_id)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
