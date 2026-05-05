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
      duplicate_records: 0,
      failed_records: 0,
      errors: [],
      duration_seconds: 0
    }

    # Assumption: CSV's must be free of malformed data
    # Some systems may wish to be lenient and parse partial lists and listing the malformed rows
    begin
      # Assumption: The CSV file has known headers for direct mapping
      CSV.foreach(file.path, headers: true).with_index(2) do |row, row_number|
        # Patient already exists in database
        # Assumption: An already exisitng patient will not need to be updated with possible new information from the CSV
        # Full implemenation would likely want to handle partial updates to existing records (Possibly toggleable)
        # Potential Consideration: If working with very large files, it may be more efficient to batch query existing patients then cross referencing in memory
        existing_patient = Patient.find_by(health_id: row["Health ID"], health_id_provincial: row["Health ID Province"])

        if existing_patient
          migration_stats[:duplicate_records] += 1
          next
        end

        newPatient = Patient.new(
          health_id: row["Health ID"].to_s.strip,
          health_id_provincial: row["Health ID Province"].to_s.strip,
          name: row["Name"].to_s.strip,
          address: row["Address"].to_s.strip,
          email: row["Email"].to_s.strip,
          phone: row["Phone Number"].to_s.strip,
          sex: row["Sex"].to_s.strip
        )

        # Check if the new patient is valid per the model validations
        # Possible Consideration: If many rows are invalid, it may be better to exit early and ask the user to fix the CSV rather than attempting to parse the entire file
        unless newPatient.valid?
          migration_stats[:failed_records] += 1
          migration_stats[:errors] << { row: row_number, errors: newPatient.errors.full_messages }
          next
        end

        if newPatient.save
          migration_stats[:successful_records] += 1
        end

        migration_stats[:total_records] += 1
      end
    rescue CSV::MalformedCSVError => e
      # Handle errors related to CSV parsing
      migration_stats[:errors] << { row: nil, errors: [ "CSV parsing error: #{e.message} | Exiting Early" ] }
    rescue => e
      # Handle any other unexpected errors that may occur during the migration process
      migration_stats[:errors] << { row: nil, errors: [ "Unexpected error: #{e.message} | Exiting Early" ] }
    end

    migration_stats[:duration_seconds] = (Time.now - start_time).round(4)

    flash[:migration_stats] = migration_stats

    redirect_to root_path
  end
end
