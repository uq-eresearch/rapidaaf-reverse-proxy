local cjson = require "cjson"
local jwt = require "resty.jwt"

local username_attribute = ngx.var.username_attribute
local rapidaaf_secret = ngx.var.rapidaaf_secret
local rapidaaf_url = ngx.var.rapidaaf_url
local session_cookie_name = ngx.var.session_cookie_name
local cookie_domain = ngx.var.cookie_domain == "" and ngx.var.cookie_domain or nil

function remove_jwt_expiry(aaf_jwt)
  ngx.log(ngx.NOTICE, aaf_jwt)
  local jwt_obj = jwt:verify(rapidaaf_secret, aaf_jwt)
  if jwt_obj["verified"] then
    ngx.log(ngx.NOTICE, cjson.encode(jwt_obj))
    -- Remove expiry
    local new_jwt_obj = {
      header=jwt_obj["header"],
      payload=jwt_obj["payload"]
    }
    new_jwt_obj["payload"]["exp"] = nil
    return jwt:sign(rapidaaf_secret, new_jwt_obj)
  else
    return aaf_jwt
  end
end

function extract_username(aaf_jwt)
  if aaf_jwt == nil or aaf_jwt == "" then
    return nil
  end
  function do_extract()
    local jwt_obj = jwt:verify(rapidaaf_secret, aaf_jwt)
    if jwt_obj["verified"] then
      local attributes = jwt_obj["payload"]["https://aaf.edu.au/attributes"]
      return attributes[username_attribute]
    else
      error(jwt_obj["reason"])
    end
  end
  local ok, retval = pcall(do_extract)
  if ok then
    return retval
  else
    ngx.log(ngx.WARN, retval)
    return nil
  end
end

local aaf_jwt = ngx.var['cookie_' .. session_cookie_name]
local username = extract_username(aaf_jwt)
if username ~= nil then
  local auth_basic = "Basic ".. ngx.encode_base64(username .. ":")
  ngx.req.set_header("Authorization", auth_basic)
  ngx.req.set_header("X-Remote-User", username)
  return
else
  local method = ngx.req.get_method()
  if method == "GET" or method == "HEAD" then
    return ngx.redirect(rapidaaf_url)
  else
    -- Read body
    ngx.req.read_body()
    if ngx.var.http_content_type and ngx.var.http_content_type:find("application/x-www-form-urlencoded", 1, true) ~= nil then
      local args = ngx.req.get_post_args()
      local aaf_jwt = args["assertion"]
      local username = extract_username(aaf_jwt)
      if username ~= nil then
        -- Add session cookie
        local cookie = session_cookie_name .. "=" .. remove_jwt_expiry(aaf_jwt)
        if cookie_domain == nil then
          ngx.header['Set-Cookie'] = { cookie .. '; path=/' }
        else
          ngx.header['Set-Cookie'] = { cookie .. '; path=/; domain=' .. ngx.var.cookie_domain }
        end
        return ngx.redirect("/")
      end
    end
    local cookie = session_cookie_name .. "="
    if cookie_domain == nil then
      ngx.header['Set-Cookie'] = { cookie .. '; expires=Thu, Jan 01 1970 00:00:00 UTC; path=/' }
    else
      ngx.header['Set-Cookie'] = { cookie .. '; expires=Thu, Jan 01 1970 00:00:00 UTC; path=/; domain=' .. ngx.var.cookie_domain }
    end
    return ngx.exit(ngx.HTTP_FORBIDDEN)
  end
end
