# Audit local documentation links in an evacpath source archive.
#
# Usage:
#   Rscript inst/scripts/audit-release-uris.R evacpath_0.2.0.tar.gz

arguments <- commandArgs(trailingOnly = TRUE)
if (length(arguments) != 1L) {
  stop("Supply one source tarball path.", call. = FALSE)
}

tarball <- normalizePath(arguments[[1L]], mustWork = TRUE)
if (!grepl("\\.tar\\.gz$", tarball, ignore.case = TRUE)) {
  stop("The audit expects an R source tarball ending in .tar.gz.", call. = FALSE)
}

extract_dir <- tempfile("evacpath-uri-audit-")
dir.create(extract_dir)
on.exit(unlink(extract_dir, recursive = TRUE, force = TRUE), add = TRUE)
utils::untar(tarball, exdir = extract_dir)

package_dirs <- list.dirs(extract_dir, recursive = FALSE, full.names = TRUE)
if (length(package_dirs) != 1L) {
  stop("Could not identify one package root in the source archive.", call. = FALSE)
}
package_dir <- package_dirs[[1L]]

all_files <- list.files(package_dir, recursive = TRUE, full.names = TRUE)
relative_files <- substring(all_files, nchar(package_dir) + 2L)
documentation_files <- all_files[
  grepl("\\.(md|rmd|html|rd)$", all_files, ignore.case = TRUE) |
    basename(all_files) %in% c("README", "NEWS")
]

extract_matches <- function(text, pattern) {
  matches <- gregexpr(pattern, text, perl = TRUE)[[1L]]
  if (identical(matches, -1L)) {
    return(character())
  }
  values <- regmatches(text, list(matches))[[1L]]
  sub(pattern, "\\1", values, perl = TRUE)
}

read_text <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  readChar(connection, nchars = file.info(path)$size, useBytes = TRUE)
}

extract_links <- function(path) {
  text <- read_text(path)
  markdown <- extract_matches(text, "!?\\[[^]]*\\]\\(([^ )]+)(?: [^)]*)?\\)")
  html <- extract_matches(text, "(?:href|src)=[\"']([^\"']+)[\"']")
  rd <- extract_matches(text, "\\\\(?:href|url)\\{([^}]+)\\}")
  unique(c(markdown, html, rd))
}

is_external <- function(link) {
  grepl("^(https?://|mailto:|doi:)", link, ignore.case = TRUE)
}

split_fragment <- function(link) {
  parts <- strsplit(link, "#", fixed = TRUE)[[1L]]
  list(path = parts[[1L]], fragment = if (length(parts) > 1L) parts[[2L]] else "")
}

check_anchor <- function(path, fragment) {
  if (!nzchar(fragment) || !grepl("\\.html?$", path, ignore.case = TRUE)) {
    return(TRUE)
  }
  text <- read_text(path)
  escaped <- gsub("([.\\^$|()\\[\\]{}*+?\\\\])", "\\\\\\1", fragment, perl = TRUE)
  grepl(
    paste0("(?:id|name)=[\"']", escaped, "[\"']"),
    text,
    perl = TRUE
  )
}

checks <- lapply(documentation_files, function(source) {
  links <- extract_links(source)
  if (length(links) == 0L) {
    return(NULL)
  }

  do.call(rbind, lapply(links, function(link) {
    # Embedded images can be very large; they are internal by construction.
    if (link == "%s" || nchar(link, type = "bytes") > 1024L ||
        startsWith(link, "data:")) {
      return(NULL)
    }
    if (startsWith(link, "file:")) {
      return(data.frame(
        source = substring(source, nchar(package_dir) + 2L),
        link = link,
        type = "file_uri",
        target = NA_character_,
        exists = FALSE,
        anchor_exists = FALSE,
        stringsAsFactors = FALSE
      ))
    }
    if (is_external(link)) {
      return(data.frame(
        source = substring(source, nchar(package_dir) + 2L),
        link = link,
        type = "external",
        target = NA_character_,
        exists = TRUE,
        anchor_exists = TRUE,
        stringsAsFactors = FALSE
      ))
    }

    parts <- split_fragment(link)
    if (!nzchar(parts$path)) {
      return(data.frame(
        source = substring(source, nchar(package_dir) + 2L),
        link = link,
        type = "anchor",
        target = substring(source, nchar(package_dir) + 2L),
        exists = TRUE,
        anchor_exists = check_anchor(source, parts$fragment),
        stringsAsFactors = FALSE
      ))
    }

    target <- normalizePath(file.path(dirname(source), utils::URLdecode(parts$path)),
      mustWork = FALSE
    )
    inside_archive <- startsWith(target, normalizePath(package_dir))
    target_exists <- inside_archive && file.exists(target)
    data.frame(
      source = substring(source, nchar(package_dir) + 2L),
      link = link,
      type = "relative",
      target = if (inside_archive) substring(target, nchar(package_dir) + 2L) else target,
      exists = target_exists,
      anchor_exists = target_exists && check_anchor(target, parts$fragment),
      stringsAsFactors = FALSE
    )
  }))
})

checks <- checks[!vapply(checks, is.null, logical(1))]
audit <- if (length(checks) == 0L) {
  data.frame(
    source = character(), link = character(), type = character(),
    target = character(), exists = logical(), anchor_exists = logical()
  )
} else {
  do.call(rbind, checks)
}

failures <- audit[
  audit$type == "file_uri" |
    (audit$type == "relative" & (!audit$exists | !audit$anchor_exists)) |
    (audit$type == "anchor" & !audit$anchor_exists),
  , drop = FALSE
]

cat("Audited source archive:", tarball, "\n")
cat("Documentation files scanned:", length(documentation_files), "\n")
cat("Local links checked:", sum(audit$type %in% c("relative", "anchor", "file_uri")), "\n")
cat("External URLs recorded:", sum(audit$type == "external"), "\n")
if (nrow(failures) > 0L) {
  print(failures, row.names = FALSE)
  stop("Release URI audit found unresolved local documentation links.", call. = FALSE)
}
cat("Release URI audit: PASS\n")
