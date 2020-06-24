-- Description: Search tinder for profiles
-- Version: 0.1.0
-- License: GPL-3.0
-- Source: accounts

function download_image(html)
  local img = html_select(html, '#user-photo')
  if last_err() then return end
  local url = img['attrs']['src']
  local req = http_request(session, 'GET', url, {
    into_blob=true,
  })
  local res = http_fetch(req)
  if last_err() then return end
  db_add('image', { value=res['blob'] })
  return res['blob']
end

function run(account)
  session = http_mksession()
  -- we can skip the accounts we've seen already
  if account['service'] == 'tinder' then return end
  local url = 'https://www.gotinder.com/@' .. account['username']
  local req = http_request(session, 'GET', url, {})
  local r = http_send(req)
  if last_err() then return end
  if r['status'] ~= 200 then return end

  local result = html_select(r['text'], '#card')
  if last_err() then return end
  local name_html = html_select(result['html'], '#name')
  if last_err() then return end

  local data = {}
  data['service'] = 'tinder'
  data['username'] = account['username']
  data['displayname'] = name_html['text']:match "^%s*(.-)%s*$"
  data['profile_pic'] = download_image(result['html'])
  db_add('account', data)
end
