class OrganizationsController < ApplicationController
  # require user
  before_action :authenticate_user!

  def import
  end

  def import_contacts
  end

  def index
    @organization_ids = Organization.where(client_account_id: current_user.client_account_id).ids
    @organization_contacts_size = OrganizationContact.where(organization_id: @organization_ids).size
  end

  def upload
    xlsx = Roo::Spreadsheet.open(params[:file].path)
    sheet_h = xlsx.parse(headers: true)
    sheet_h[1..-1].each do |row|
      org = Organization.find_or_create_by(
        user_id: current_user.id,
        organization_code: row["Organization Code"],
        unloco: row["UNLOCO"]
      )

      org.assign_attributes(
        user_id: current_user.id,
        client_account_id: current_user.client_account_id,
        organization_code: row["Organization Code"],
        full_name: row["Full Name"],
        unloco: row["UNLOCO"],
        city: row["City"],
        state: row["State"],
        branch: row["Branch"],
        screening_status: row["Scrn."],
        achievable_business: row["Achievable Business"],
        category: row["Category"],
        country_region: row["Country/Region"],
        employer_identification_number: row["Employer Identification Number"],
        imp_bond_last_queried_date: row["Imp. Bond Last Queried Date"],
        created_by: row["Created By"],
        created_time_utc: row["Created Time (UTC)"],
        last_edit: row["Last Edit"],
        last_edited_time_utc: row["Last Edited Time (UTC)"],
        address_1: row["Address 1"],
        address_2: row["Address 2"],
        email: row["Email"]
      )

      org.save if org.valid? && org.changed?
    end

    redirect_to organizations_path
  end

  def upload_contacts
    xlsx = Roo::Spreadsheet.open(params[:file].path)
    sheet_h = xlsx.parse(headers: true)
    sheet_h[1..-1].each do |row|
      contact = OrganizationContact.find_or_create_by(
        contact_name: row["Contact Name"],
        organization_code: row["Organization"],
        organization_name: row["Organization Name"],
        email: row["Email"]
      )

      org = Organization.find_by(
        client_account_id: current_user.client_account_id,
        organization_code: row["Organization"]
      )

      unless org
        org = Organization.create(
          user_id: current_user.id,
          client_account_id: current_user.client_account_id,
          organization_code: row["Organization"],
          organization_name: row["Organization Name"],
          unloco: row["Working Location"]
        )
      end

      contact.organization_id = org.id if org

      contact.assign_attributes(
        contact_name: row["Contact Name"],
        organization_code: row["Organization"],
        organization_name: row["Organization Name"],
        working_location: row["Working Location"],
        title: row["Title"],
        email: row["Email"],
        job_category: row["Job Category"],
        password_instruction_sent_by: row["Password Instruction Sent By"],
        password_instruction_last_sent_time: row["Password Instruction Last Sent Time"],
        active: Utils.to_boolean(row["Active"]),
        primary_workplace: row["Primary Workplace"],
        web_access: Utils.to_boolean(row["Web Access"]),
        verified: Utils.to_boolean(row["Verified"]),
        created_by: row["Created By"],
        created_time_utc: row["Created Time (UTC)"],
        last_edit: row["Last Edit"],
        last_edited_time_utc: row["Last Edited Time (UTC)"],
        csv: Utils.to_boolean(row["CSV"]),
        phone: row["Phone"],
        mobile: row["Mobile"],
        notify_mode: row["Notify Mode"],
        branch_address: row["Branch Address"],
        web_access_superseded: Utils.to_boolean(row["Web Access Superseded"]),
        organization_id: org.id
      )

      contact.save if contact.valid? && contact.changed?

      redirect_to organizations_path, notice: "Contacts uploaded successfully"
    end
  end

  def show
  end
end
