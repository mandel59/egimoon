id = (...) -> ...
pack = (...) -> {...}
map = (f) -> (t) -> [f x for x in *t]
dup = map id
head = (t) -> t[1]
tail = (t) ->
  with u = dup t
    table.remove u, 1
take = (t, i) ->
  u = dup t
  table.remove u, i
  return t[i], u
join = (t) ->
  u = {}
  for v in *t
    for w in *v
      table.insert u, w
  return u
bind = (x, t) ->
  join map ((f) -> f x) , t

show = (d, n = '') ->
  if type(d) == 'table' and #d > 0
    "{#{table.concat ((map show) d), ','}}"
  else
    tostring(d)

match_one = (value, datatype, pattern) ->
  datatype[head pattern] value, unpack tail pattern

match_all = (target, datatype, patterns) -> 
  local m
  for p, f in pairs patterns
    m = match_one target, datatype, p
    if m ~= nil then return f unpack m
  return nil

var = -> { var }
cons = (h, t) -> { cons, h, t }

List = (datatype) -> {
  [cons]: (v, hp, tp) ->
    if type(v) == 'table' and #v > 0
      a = match_one (head v), datatype, hp
      b = match_one (tail v), (List datatype), tp
      if a ~= nil and b ~= nil then {a, b} else nil
    else
      nil
  [var]: (v) ->
    if type(v) == 'table'
      for i in *v
        if match_one(i, datatype, var!) == nil
          return nil
      v
    else nil
}

Number = {
  [var]: (v) ->
    if type(v) == 'number' then v else nil
}

print show match_all {1, 2, 3}, (List Number),
  [cons var!, var!]: pack
