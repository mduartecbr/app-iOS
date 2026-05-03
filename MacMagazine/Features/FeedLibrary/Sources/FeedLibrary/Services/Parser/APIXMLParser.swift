import Foundation

class APIXMLParser: NSObject, XMLParserDelegate {

	// MARK: - Properties -

	let numberOfPosts: Int
	let category: String
	var parseFullContent: Bool
	let continuation: CheckedContinuation<[XMLPost], Error>?
    let dateParser = DateParser()

    var posts = [XMLPost]()

	var currentPost = XMLPost()
	var processItem = false
	var value = ""
	var attributes: [String: String]?
	var parsedPosts = 0

	// MARK: - Init -

	init(numberOfPosts: Int = -1,
		 category: String,
		 parseFullContent: Bool = false,
		 continuation: CheckedContinuation<[XMLPost], Error>?) {
		self.numberOfPosts = numberOfPosts
		self.category = category
		self.parseFullContent = parseFullContent
		self.continuation = continuation
	}

	// MARK: - Parse Delegate -

	func parser(_ parser: XMLParser,
				didStartElement elementName: String,
				namespaceURI: String?,
				qualifiedName qName: String?,
				attributes attributeDict: [String: String] = [:]) {

		value = ""
		if elementName == "item" {
			processItem = true
			currentPost = XMLPost()
		}
		if elementName == "media:content" {
			attributes = attributeDict
		}
		if elementName == "enclosure" {
			attributes = attributeDict
		}
	}

	func parser(_ parser: XMLParser, foundCharacters string: String) {
		if processItem {
			value += string
		}
	}

	func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
		if processItem {
			value = value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

			switch elementName {
			case "post-id":
				currentPost.postId = value
			case "title":
				currentPost.title = value
			case "link":
				currentPost.link = value
			case "pubDate":
                currentPost.pubDate = dateParser.parse(value)
			case "category":
				if currentPost.categories.isEmpty {
					currentPost.categories = []
					currentPost.categories.append(category)
				}
				currentPost.categories.append(value)
			case "description":
				currentPost.excerpt = value
			case "media:content":
				guard let url = attributes?["url"] else {
					return
				}
				currentPost.artworkURL = url
			case "enclosure":
				guard let url = attributes?["url"] else {
					return
				}
				currentPost.podcastURL = url
                currentPost.podcastSize = Double(attributes?["length"] ?? "0") ?? 0
			case "itunes:subtitle":
				currentPost.podcast = value
			case "itunes:duration":
				currentPost.duration = value
			case "rawvoice:embed":
				currentPost.podcastFrame = value
			case "item":
				posts.append(currentPost)
				parsedPosts += 1
				processItem = false
				if numberOfPosts > 0 &&
					parsedPosts >= numberOfPosts {
					parser.abortParsing()
				}
			case "guid":
				currentPost.shortURL = value
			case "content:encoded":
				currentPost.playable = value.contains("youtube.com/embed/")
				currentPost.fullContent = parseFullContent ? value.htmlDecoded.clean : ""
				// Fallback: if no <media:content> tag provided an artwork URL,
				// extract the first <img src="..."> from the HTML content.
				// This handles WordPress sites whose RSS feeds don't emit media:content
				// (e.g. WordPress.com hosted sites without a featured-image-in-RSS plugin).
				if currentPost.artworkURL.isEmpty,
				   let imageURL = Self.extractFirstImageURL(from: value) {
					currentPost.artworkURL = imageURL
				}
			case "dc:creator":
				currentPost.creator = value
			default:
				return
			}
		}
	}

	func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
		if posts.count == numberOfPosts {
			continuation?.resume(returning: posts)
		} else {
			continuation?.resume(throwing: parseError)
		}
	}

	func parserDidEndDocument(_ parser: XMLParser) {
		continuation?.resume(returning: posts)
	}

	// MARK: - Helpers -

	/// Extracts the URL of the first `<img>` tag found inside an HTML string.
	/// Used as a fallback to obtain a post's artwork when the RSS feed does not
	/// emit a `<media:content>` element (e.g. some WordPress.com configurations).
	///
	/// Matches both single- and double-quoted `src` attributes and is case-insensitive.
	/// Returns `nil` if no `<img>` is found or the matched URL is empty.
	private static func extractFirstImageURL(from html: String) -> String? {
		let pattern = #"<img\b[^>]*?\bsrc\s*=\s*["']([^"']+)["']"#
		guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
			return nil
		}
		let range = NSRange(html.startIndex..., in: html)
		guard let match = regex.firstMatch(in: html, options: [], range: range),
			  let urlRange = Range(match.range(at: 1), in: html) else {
			return nil
		}
		let url = String(html[urlRange]).trimmingCharacters(in: .whitespacesAndNewlines)
		return url.isEmpty ? nil : url
	}
}
