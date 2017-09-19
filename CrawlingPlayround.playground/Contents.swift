//: Playground to test crawling


import Cocoa
import Kanna
import Regex
import TarantulaPluginCore


let objectUrl = URL(string: "https://examplewebsite/treatments/show/20573-dabigatran-side-effects-and-efficacy")!

let data = try! String(contentsOf: objectUrl)

guard let html = Kanna.HTML(html: data, encoding: .utf8) else {
    throw CrawlError(url: objectUrl, info: "Unable to parse HTML")
}

let name = html.xpath("//li[@class='toolbar-title']//span[@itemprop='name']").first?.text

let category = html.xpath("//div[@id='overview']//header[@id='summary']/../p[strong='Category:']/a/@href").flatMap { element in
    element.text
}

let types = html.xpath("//div[@id='overview']//header[@id='summary']/../p[strong='Most popular types:']//a/@href").flatMap { element in
    element.text
}

let generic = html.xpath("//div[@id='overview']//header[@id='summary']/../p[strong='Generic name:']//a/@href").flatMap { element in
    element.text
}

let description = html.xpath("//div[@id='overview']//header[@id='summary']/../p[@itemprop='description']").first?.text

let purposes = html.xpath("//div[@id='overview']//div[@data-widget='treatment_report_section']/table[caption='Reported purpose & perceived effectiveness']/tbody/@data-url").flatMap { element in
    element.text
}

let patients = html.xpath("//div[@id='overview']//div[@class='glass-panel']/a[contains(normalize-space(text()),'See all')]/@href").flatMap { element in
    element.text
}

let sideeffect_severities: [(String, Int)?] = html.xpath("//div[@id='overview']//div[h2='Side effects']//tr[@data-yah-key='overall_side_effects']").flatMap { element in
    guard let id_value_str = element.xpath("@data-yah-value").first?.text,
        let id_value = Int(id_value_str) else { return nil }

    let tmpArray = element.xpath("td")

    guard tmpArray.count == 3,
        let name = (tmpArray[0].xpath("text()").flatMap { x in x.text?.trimmingCharacters(in: .whitespacesAndNewlines) } .filter { x in x.count != 0 }.first),
        let countStr = tmpArray[2].xpath("a").first?.text,
        let count = Int(countStr) else { return nil }

    return (name, count)
}

let dosages: [(String, Int)?] = html.xpath("//div[@id='overview']//div[h2='Dosages']//tr[@data-yah-key='dosage']").flatMap { element in
    guard let id_value = element.xpath("@data-yah-value").first?.text else { return nil }

    let tmpArray = element.xpath("td | th")

    guard tmpArray.count == 3,
        let name = (tmpArray[0].xpath("text()").flatMap { x in x.text?.trimmingCharacters(in: .whitespacesAndNewlines) } .filter { x in x.count != 0 }.first),
        let countStr = tmpArray[1].xpath("a").first?.text,
        let count = Int(countStr) else { return nil }

    return (name, count)
}

let switches = html.xpath("//div[@id='overview']//div[h2='What people switch to and from']//div[@data-widget='treatment_report_section']/table/tbody/@data-url").flatMap { element in
    element.text
}


