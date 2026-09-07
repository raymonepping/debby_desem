-- EPUB does not safely support a <details> block containing section headings.
-- Keep its contents, render the summary as a real EPUB section heading, and
-- remove the wrapper tags so Pandoc can generate correctly nested XHTML.
function RawBlock(element)
  if element.format ~= "html" then
    return nil
  end

  if element.text:match("^<details>") then
    local summary = element.text:match("<summary>(.-)</summary>")

    if summary then
      summary = summary:gsub("<[^>]+>", "")
      return pandoc.Header(
        2,
        {pandoc.Str(summary)},
        pandoc.Attr(
          "snelle-route-van-starter-tot-brood",
          {},
          {["epub:type"] = "introduction"}
        )
      )
    end

    return {}
  end

  if element.text:match("^</details>") then
    return {}
  end

  return nil
end

-- Add EPUB structural semantics without changing the Markdown headings.
function Header(element)
  if element.level ~= 2 then
    return nil
  end

  local heading = pandoc.utils.stringify(element.content)

  if element.identifier == "inhoud-in-hoofdlijnen" then
    element.attributes["epub:type"] = "toc"
  elseif element.identifier == "terminologie" then
    element.attributes["epub:type"] = "glossary"
  elseif heading:match("^4[6-9]%.") or heading:match("^50%.") then
    element.attributes["epub:type"] = "appendix"
  else
    element.attributes["epub:type"] = "chapter"
  end

  return element
end
