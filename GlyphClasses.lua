ucq_GLYPH_CLASSES = {
  ["Paladin"] = {
    43368,
    43367,
  },
  ["Death Knight"] = {
    1, 3, 5
  }
}

function getClass(id)
  for k, v in pairs(ucq_GLYPH_CLASSES) do
    if v[id] ~= nil then
      return k
    end
  end
  return nil
end

function ppp(s)
  print(s)
end




