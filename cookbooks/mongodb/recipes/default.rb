#
# Cookbook Name:: mongodb
# Recipe:: default


directory "/data/master" do
  owner node[:owner_name]
  group node[:owner_name]
  mode 0755
  recursive true
  not_if { File.directory?('/data/master') }
end

# The recipe is not using a slave yet but it will create the directory
# so that it is there for the future
directory "/data/slave" do
  owner node[:owner_name]
  group node[:owner_name]
  mode 0755
  recursive true
  not_if { File.directory?('/data/slave') }
end
  
execute "install-mongodb" do
  # http://aws.amazon.com/ec2/instance-types/ for sizes
  size = `curl -s http://instance-data.ec2.internal/latest/meta-data/instance-type`

  # small instances and high CPU medium instances have 32 bit architecture.
  # MongoDB has a max data-size limit on 32 bit architectures of ~2.5 GB.
  if size == 'm1.small' or size == 'c1.medium'
    mongo_root = "mongodb-linux-i686-1.4.0"
  else
    mongo_root = "mongodb-linux-x86_64-1.4.0"
  end

  mongo_file = "#{mongo_root}.tgz"

  command %Q{
    curl -O http://downloads.mongodb.org/linux/#{mongo_file} &&
    tar zxvf #{mongo_file} &&
    mv #{mongo_root} /usr/local/mongodb &&
    rm #{mongo_file}
  }
  not_if { File.directory?('/usr/local/mongodb') }
end
  
execute "add-to-path" do
  command %Q{
    echo 'export PATH=$PATH:/usr/local/mongodb/bin' >> /etc/profile
  }
  not_if "grep 'export PATH=$PATH:/usr/local/mongodb/bin' /etc/profile"
end
  
remote_file "/etc/init.d/mongodb" do
  source "mongodb"
  owner "root"
  group "root"
  mode 0755
end

execute "add-mongodb-to-default-run-level" do
  command %Q{
    rc-update add mongodb default
  }
  not_if "rc-status | grep mongodb"
end

execute "ensure-mongodb-is-running" do
  command %Q{
    /etc/init.d/mongodb start
  }
  not_if "pgrep mongod"
end



