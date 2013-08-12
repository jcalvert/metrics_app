class CreateCoverageReports < ActiveRecord::Migration
  def change
    create_table :coverage_reports do |t|
      t.string :sha
      t.datetime :publication_date
      t.float :coverage
      t.string :key
      t.string :repo
      t.string :build_id
      t.timestamps
    end
  end
end
