-- Description: Uses search.social to search for accounts on the fediverse
-- Version: 0.1.0
-- License: GPL-3.0
-- Source: accounts

function trim(s)
  if s == nil or s == '' then return '' end
  return s:match "^%s*(.-)%s*$"
end

function download_image(html)
  local img = html_select(html, 'img')
  if last_err() then return end
  local src = img['attrs']['src']
  local url = 'https://search.social' .. src
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
  local url = 'https://search.social/profiles/' .. account['username']
  local req = http_request(session, 'GET', url, {})
  local r = http_send(req)
  if last_err() then return end
  if r['status'] ~= 200 then return end

  local results = html_select_list(r['text'], 'article')
  if last_err() then return end
  if #results == 0 then return end

  for i = 1, #results do
    local as = html_select_list(results[i]['html'], '.content a')
    local data = {}
    data['url'] = trim(as[1]['attrs']['href'])
    data['display_name'] = trim(as[1]['text'])
    data['username'] = trim(as[2]['text']):match "^(.-)@.*$"
    data['service'] = trim(as[2]['text']):match "^.*@(.-)$"
    data['profile_pic'] = download_image(results[i]['html'])
    db_add('account', data)
  end
end
