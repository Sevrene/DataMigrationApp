class PagesController < ApplicationController
  def home
      @migration_stats = flash[:migration_stats]
  end

  def upload
    # NOTE: Ideally here we would present a loader/progress bar to the frontend as a good UX improvement for large files
    file = params[:file]

    start_time = Time.now

    migration_stats = {
      total_records: 0,
      successful_records: 0,
      failed_records: 0,
      errors: [],
      duration_seconds: 0
    }

    CSV.foreach(file.path, headers: true) do |row|
      patient = Patient.new(
        health_id: row["health_id"],
        health_id_provincial: row["health_id_provincial"],
        name: row["name"],
        address: row["address"],
        email: row["email"],
        phone: row["phone"],
        sex: row["sex"]
      )

      if patient.save
        migration_stats[:successful_records] += 1
      else
        # TODO: Properly parse and handle errors (e.g. validation errors, duplicates, etc.) instead of just counting them
        migration_stats[:failed_records] += 1
        migration_stats[:errors] << { row: row.to_h, errors: patient.errors.full_messages }
      end

      migration_stats[:total_records] += 1
    end

    migration_stats[:duration_seconds] = Time.now - start_time

    flash[:migration_stats] = migration_stats

    redirect_to root_path
  end
end
