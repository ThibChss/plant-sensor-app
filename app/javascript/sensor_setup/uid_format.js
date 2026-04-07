const CHARS_TO_REPLACE_REGEXT = /[^A-Za-z0-9]/g

export function formatUidString(uid) {
  const upperUid = uid.replace(CHARS_TO_REPLACE_REGEXT, "").trim().toUpperCase()

  if (upperUid.length === 0) return ""
  if (upperUid.length <= 2 && startsWithGP(upperUid)) return upperUid


  return formatWithGP(upperUid)
}

function formatWithGP(uid, stringBody = null) {
  if (startsWithGP(uid)) {
    stringBody = uid.slice(2, 12)
  } else {
    stringBody = uid.slice(0, 10)

    return formattedString(stringBody)
  }

  return formattedString(stringBody)
}

function startsWithGP(uid) {
  return uid.startsWith("GP")
}

function formattedString(stringBody) {
  return `GP-${stringBody.slice(0, 5)}${stringBody.length > 5 ? `-${stringBody.slice(5)}` : ""}`
}
