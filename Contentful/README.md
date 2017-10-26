# Contentful

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/niceagency/LocationMonitor) [![Carthage compatible](https://img.shields.io/badge/twitter-%40niceagency-blue.svg)](https://twitter.com/niceagency)

#### Supports Swift 4

A slim swift wrapper around reading and writing data from Contentful. This is an interface to Contentful's content management API.
The offical Contentful Swift API current only supports the content delivery API, and hence is unable to write data to Contentful.

## Features

* Reads and writes data from custom data objects to Contentful, using Contentful's Content Management API
* Supports pagination of results
* Supports reading and writing data for specified locales.

## Installation


To integrate Contentful into your Xcode project using Carthage, specify it in your Cartfile:

`github "niceagency/Contentful"`

Run carthage update to build the framework and drag the built Contentful.framework into your Xcode project.

## Requirements

System requirements

* iOS 10.3+
* Xcode 9.0+
* Swift 4.0+

Can be used in conjunction with [base] (https://github.com/niceagency/Base) for handling networking.

## Usage

### To read data from Contentful to a custom data model:

Create an object that conforms to the Readable protocol. This object should have the following static functions:

   * `static func contentfulEntryType() -> String`
   * `static func unboxer(ofField field: String) -> UnboxedType?`
   * `static func creator(withFields fields: UnboxedFields) -> Self`

   The first of these functions should return the name used by Contentful for the content type. For example:

   ```static func contentfulEntryType() -> String {
        return "device"
    }```

The `unboxer` function is used to map data from Contentful fields to the correct Swift data type. Use a `switch`  statement to return the type your model expects for each field it is interested in. For example:

```static func unboxer(ofField field: String) -> UnboxedType? {
        switch field {
        case "name:
            return .string
        case "number":
            return .int
        }
    }```

The `creator` function is used to create an instance of your custom data object. This can be used in conjuction with an `init` function as follows:

```static func creator(withFields fields: UnboxedFields) -> Device {
        let device = Device(withFields: fields)
        return device
    }```

  ```private init(withFields fields: UnboxedFields) {
        name = fields["name"] as! String
        number = fields["number"] as? Int
    }```

  You can also provide a managed object context here if you are using Core Data.

   #### To prepare a data request to Contentful:
   use the prepareRequest function:

   `public static func prepareRequest(forContent contentType: String, fromSpace spaceId: String,  page: Page) -> (endpoint: String, query: [URLQueryItem])`

   where `contentType` is the type used to describe the content type in Contentful. You can pass either a string, or the `contentfulEntryType()` function of your data model object.
   `spaceId` is the name of the Contentful space that holds your data. `page` is a instance of a `Page` object that describes which page of results you are interested in. You can use pass the `Page.getFirstPage(itemsPerPage: Int)` function, create your own `Page` instance, or increment/decrement a `Page` object returned from a previous request.

   Use the returned endpoint and URLQueryItems to make a network request to Contentful, and then use the `unboxResponse` function to unpack the returned data into your data object.

  ``` public static func unboxResponse<T>(data: Data, locale: Locale?, with fieldUnboxer: @escaping ((String) -> UnboxedType?), via creator: @escaping ((UnboxedFields) -> T?)) -> Result<PagedResult<T>>```

  This function takes as the `data` parameter the data returned from the network request to Contentful. The optional `locale` parameter takes an instance of a `Locale` object, which defines a favoured and fallback locale to use when reading data. If this is set to `nil`, the data will be returned using the first locale it finds.
  The `fieldUnboxer` parameter is a closure that matches the signature of the `unboxer` function from the `Readable` protocol. Hence you can pass this method of your custom data object. Similarly, for the `creator` closure, you can pass the `creator` function from your data object. For example:

  ```let result: Result<PagedResult<T>> =  Contentful.unboxResponse(data: data, locale: locale, with: device.unboxer, via: device.creator)```

  The returned `PagedResult` object contains an array of data objects, and a `Page` instance describing which page of data was returned.

### To write data to Contentful from a custom data object:

Make your data object conform to `Contentful.Encodable` - which is a combination of both `Encodable`  - the standard Swift 4 Json Encoding protocol, and `Writable` which requires your object to set the following properties:

```var contentful_id: String { get }
var contentful_version: Int { get}```

where contentful_id is the Id String of the entry in Contentful, and `contentful_version` stores the current version of the data.

Use ```public static func encode<T: Encodable>(object: T, locale: LocaleCode)``` to encode your data object to Contentful compatible data.

If succesful, this function returns a tuple containing the encoded Data, and a SysData object that contains the the `id` String and `version` number from your data object.

Use a `.put` request to send the encoded data to Contentful, using the endpoint
`/spaces/{spaceId}/entries/{sysData.id}` where spaceId is Id of the Contentful space storing your data, and sysData.id is the `id` String from the sysData object.

You also need to provide the following Http headers:
 * ``"X-Contentful-Version",sysData.version`
 * `"Content-Type","application/vnd.contentful.management.v1+json"`

  ## Contributions

  If you wish to contribute to Contentful please fork the repository and send a pull request or raise an issue within GitHub.

  ## License

  Contentful is released under the MIT license. See LICENSE for details.
