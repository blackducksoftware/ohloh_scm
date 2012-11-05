 module Scm::Adapters
   class MtnAdapter < AbstractAdapter
     
     # How to use Monotone pull :
     # The target Adapter should contain a path in the :url field where to clone the repository
     # Optionnaly but recommended, you can provide a path to a database file.
     # This database will be created if not present or re-use if existing
     # By default, the database will be handled by Monotone
     # The from adapter must contain a standard url in the url field as defined in
     # http://www.monotone.ca/docs/Network.html#Network
     # The other field that should be filled is branch_name. It will allow to filter
     # the source retrieved from remote database.
     # When not provided, branch_name will first be set to '*', filling the local
     # database with all branches but the working copy cloned will be the first branch found.
     def pull(from, &block)
       raise ArgumentError.new("Cannot pull from #{from.inspect}") unless from.is_a?(MtnAdapter)
       logger.info { "Pulling #{from.url}" }

       yield(0,1) if block_given? # Progress bar callback

       db_opt = ""
       if @database != '' then
         db_opt = "--db #{self.database} "

         # Must create the database first if it does not exist
         if File.exists?(@database) == false then
           run "mtn db init #{db_opt}"
         end
       end

       unless self.exist?
         run "mkdir -p '#{self.url}'"
         run "rm -rf '#{self.url}'"

         #if no branch is specified, use the wildcard
         from.branch_name = '*' unless from.branch_name or from.branch_name == ''

         #Pulling into the database
         run "mtn pull #{db_opt} '#{from.url}?#{from.branch_name}'"

         #If we did not choose a specific branch
         if from.branch_name == '*' then
           # We arbitrary find the first branch and assign it to the branch_name var
           from.branch_name = run("mtn #{db_opt} ls branches | head -1").chomp
         end

         self.branch_name = from.branch_name

         #We can now create the working copy
         run "mtn #{db_opt} co --branch '#{from.branch_name}' '#{self.url}'"

       else
         # Just go into the working copy and synchronize
         run "cd '#{self.url}' && mtn #{db_opt} revert . && mtn #{db_opt} sync"
       end

       yield(1,1) if block_given? # Progress bar callback
     end

   end
 end
