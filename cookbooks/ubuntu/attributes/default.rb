#
# Cookbook Name:: ubuntu
# Attribute File:: default
#
# Copyright 2011, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# @todo move settings to data_bag
case platform
when "ubuntu"
  set[:ubuntu][:archive_url]  = "http://192.168.100.108:8080/apt-mirror/ftp.daum.net/ubuntu"
  set[:ubuntu][:security_url] = "http://192.168.100.108:8080/apt-mirror/ftp.daum.net/ubuntu"
end
