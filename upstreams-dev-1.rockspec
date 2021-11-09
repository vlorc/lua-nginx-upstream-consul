package = "upstreams"
version = "dev-1"
source = {
   url = "*** please add URL for source tarball, zip or repository here ***"
}
description = {
   detailed = "A lua module for OpenResty, can dynamically update the upstreams from etcd and kubernetes.",
   homepage = "*** please enter a project homepage ***",
   license = "*** please specify a license ***"
}
build = {
   type = "builtin",
   modules = {
      upstreams = "upstreams.lua"
   }
}
