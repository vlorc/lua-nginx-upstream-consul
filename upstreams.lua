local cjson = require "cjson"
local http = require "resty.http"
local balancer = require "ngx.balancer"

local _M = {}

_M._VERSION="0.1"

function indexOf(array, value)
    for i, v in ipairs(array) do
        if v == value then
            return i
        end
    end
    return nil
end


function _M:refresh(tag)
    local cli = http.new()

    local res, err = cli:request_uri("http://127.0.0.1:8500/v1/catalog/services")
    if not res then
        ngx.log(ngx.ERR, "upstreams refresh failed: ", err)
        return
    end

    local data = cjson.decode(res.body)

    for key, value in pairs(data) do
        if not tag or indexOf(value, tag) then
            self.update(key)
        end
    end
end

function _M.update(name)
    local cli = http.new()

    local res, err = cli:request_uri("http://127.0.0.1:8500/v1/health/service/"..name.."?passing=1")
    if not res then
        ngx.log(ngx.ERR, "upstreams update failed: ", err)
        return
    end

    local data = cjson.decode(res.body)

    local upstreams = {}
    for i, v in ipairs(data) do
        upstreams[i] = {ip=v.Service.Address, port=v.Service.Port}
    end

    ngx.shared.lreu_upstream:set(name, cjson.encode(upstreams))

    if upstreams then
        ngx.log(ngx.INFO, "upstreams update: ", table.getn(upstreams))
    end
end

function _M.rr(name)
    if not name then
        local m = ngx.re.match(ngx.var.host, (ngx.re.sub(ngx.var.server_name, "\\*", "([a-z0-9]+)")))
        if not m then
            return false
        end
        name = m[1]
    end

    local data = ngx.shared.lreu_upstream:get(name);

    if not data then
        return false
    end

    local upstreams = cjson.decode(data);
    local length = table.getn(upstreams);
    local pick = upstreams[1 == length and 1 or math.random(1, length)];

    if pick then
        balancer.set_current_peer(pick.ip, pick.port);
        return true
    end

    return false
end

return _M