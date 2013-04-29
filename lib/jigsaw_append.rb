# Upload is Resque Job class that responds to 'perform' method for Merge
class JigsawAppend < Resque::JobWithStatus
  @queue = :jigsaw_q
  def perform
    if Resque.size('jigsaw_q') == 0
      task = JigsawTask.find(:first)
      task.batch_enrichment self
      self.completed
    end
  end
end
