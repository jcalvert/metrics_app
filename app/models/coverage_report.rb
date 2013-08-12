class CoverageReport < ActiveRecord::Base
  attr_accessible :build_id, :coverage, :publication_date, :repo, :sha, :key

  def derivation
  	(self.coverage - CoverageReport.average('coverage')).round(3)*100
  end
end
