#!/usr/bin/env ruby
###########################################################
# Name:        map-ipaddrs.rb
# Description: simply output IP addresses and what adapters
#   they belong to.
###########################################################
require 'socket'

# Logic
addr_infos = Socket.getifaddrs
addr_infos.each do |addr_info|
    if addr_info.addr
        puts "#{addr_info.name}: #{addr_info.addr.ip_address}" if addr_info.addr.ipv4? or addr_info.addr.ipv6?
    end
end
