//
//  RequestCaller.swift
//  RxSwiftConnect
//
//  Created by Sakon Ratanamalai on 2019/05/05.
//

import Foundation
import Combine
import CombineExt

public typealias DecodError = Decodable & ErrorInfo

public class Requester:NSObject{
    
    private let baseUrl:String
    private lazy var decoder = JSONDecoder()
    private let sessionConfig:URLSessionConfiguration
    private let preventPinning:Bool
    private let hasVersion:Bool
    
    public init(initBaseUrl:String,
                timeout:Int,
                isPreventPinning:Bool,
                initSessionConfig:URLSessionConfiguration,
                hasVersion:Bool = false){
        
        self.baseUrl = initBaseUrl
        //self.requester = initRequester
        self.preventPinning = isPreventPinning
        self.sessionConfig = initSessionConfig
        self.sessionConfig.timeoutIntervalForRequest = TimeInterval(timeout)
        self.hasVersion = hasVersion
    }
    
    public func postQuery<DataResult:Decodable, CustomError:DecodError>(path:String,
                                                                        sendParameter:Encodable? = nil,
                                                                        header:[String:String]? = nil) -> AnyPublisher<DataResult, CustomError>{
        
     
        
        let requestParameter = RequestParameter(
            httpMethod: .post,
            path: path,
            baseUrl: self.baseUrl,
            query: sendParameter?.dictionaryValue ?? nil,
            headers: header,
            hasVersion: hasVersion).asURLRequest()
        
        return  self.call(requestParameter,config: sessionConfig,isPreventPinning: preventPinning)
        
    }
    
    public func post<DataResult:Decodable, CustomError:DecodError>(path:String,
                                                                   sendParameter:Encodable? = nil,
                                                                   header:[String:String]? = nil) -> AnyPublisher<DataResult, CustomError>{
        
      
        let requestParameter = RequestParameter(
            httpMethod: .post,
            path: path,
            baseUrl: self.baseUrl,
            payload: sendParameter?.dictionaryValue ?? nil,
            headers: header,
            hasVersion: hasVersion).asURLRequest()
        
        return  self.call(requestParameter,config: sessionConfig,isPreventPinning: preventPinning)
        
    }
    
    public func post<DataResult:Decodable, CustomError:DecodError>(path:String,
                                                                   sendParameter:Encodable? = nil,
                                                                   header:[String:String]? = nil,
                                                                   version:String) -> AnyPublisher<DataResult, CustomError>{
        
    
        let requestParameter = RequestParameter(
            httpMethod: .post,
            path: path,
            baseUrl: self.baseUrl,
            payload: sendParameter?.dictionaryValue ?? nil,
            headers: header,
            version: version,
            hasVersion: hasVersion).asURLRequest()
        
        return  self.call(requestParameter,config: sessionConfig,isPreventPinning: preventPinning)
        
    }
#if canImport(UIKit)
    public func postBoundary<DataResult:Decodable, CustomError:DecodError>(path:String,sendParameter:Encodable? = nil,
                                                                           header:[String:String]? = nil,
                                                                           dataBoundary:BoundaryCreater.DataBoundary? = nil) -> AnyPublisher<DataResult, CustomError>{
        
        let boundaryCreater = BoundaryCreater()
        
        var requestParameter = RequestParameter(
            httpMethod: .post,
            path: path,
            baseUrl: self.baseUrl,
            payload: nil,
            headers: header,
            hasVersion: hasVersion).asURLRequest()
        
        let data = boundaryCreater
            .addToBoundary(sendParameter?.dictionaryStringValue, dataBoundary: dataBoundary)
            .addEndBoundary()
            .setRequestMultipart(&requestParameter)
        
        return  self.callUpload(requestParameter,config: sessionConfig,isPreventPinning: preventPinning, dataUploadTask : data)
    }
#endif
    
    public func get<DataResult:Decodable, CustomError:DecodError>(path:String,sendParameter:Encodable? = nil) -> AnyPublisher<DataResult, CustomError>{
        
     
        
        let requestParameter = RequestParameter(
            httpMethod: .get,
            path: path,
            baseUrl: self.baseUrl,
            query: sendParameter?.dictionaryValue ?? nil,
            headers: nil,
            hasVersion: hasVersion).asURLRequest()
        
        return  self.call(requestParameter,config: sessionConfig, isPreventPinning: preventPinning)
        
    }
    
    public func getRaw<CustomError:DecodError>(path:String) -> AnyPublisher<RawResponse, CustomError>{
    
        var requestParameter = RequestParameter(
            httpMethod: .get,
            path: path,
            baseUrl: self.baseUrl,
            payload:  nil,
            headers: nil,
            hasVersion: hasVersion).asURLRequest()
        requestParameter.url = URL(string: path)
        
        return  self.call(requestParameter,config: sessionConfig,isPreventPinning: preventPinning)
        
    }
    
 
    
    
    func call<DataResult:Decodable, CustomError:DecodError>(_ request: URLRequest, config:URLSessionConfiguration,isPreventPinning:Bool)
        -> AnyPublisher<DataResult, CustomError> {
            
            return AnyPublisher<DataResult, CustomError>.create { [weak self] subscriber in
                
                let sessionPinning = SessionPinningDelegate(statusPreventPinning: isPreventPinning);
                let urlSession = URLSession(configuration: config, delegate: sessionPinning, delegateQueue: nil)
                let task = urlSession.dataTask(with: request) {
                    self?.processResult($0, $1, $2,
                                        subscriber: subscriber,
                                        request: request)
                }
                
                task.resume()
                
                return AnyCancellable {[weak task] in
                    task?.cancel()
                }
            }
    }
    
    
    func call<CustomError:DecodError>(_ request: URLRequest, config:URLSessionConfiguration,isPreventPinning:Bool)
        -> AnyPublisher<RawResponse, CustomError> {
            
            return AnyPublisher<RawResponse, CustomError>.create {  subscriber in
                
                let sessionPinning = SessionPinningDelegate(statusPreventPinning: isPreventPinning);
                let urlSession = URLSession(configuration: config, delegate: sessionPinning, delegateQueue: nil)
                let task = urlSession.dataTask(with: request) { data, response, error in
                    
                    if error != nil {
                        
                        let customError = CustomError(error: error!)
                        subscriber.send(completion: .failure(customError))
                        
                    }else{
                     
                        if let httpResponse = response as? HTTPURLResponse{
                            let statusCode = httpResponse.statusCode
                            
                            let _data = data ?? Data()
                            if statusCode == 200 {
                                let plainResponse = RawResponse(statusCode: statusCode, data: _data)
                                subscriber.send(plainResponse)
                                subscriber.send(completion: .finished)
                            } else {
                                let customError = CustomError(responseCode: httpResponse.statusCode)
                                subscriber.send(completion: .failure(customError))
                            }
                            
                        }else{
                            let customError = CustomError(unknowError: "Error URLSession")
                            subscriber.send(completion: .failure(customError))
                        }
                    }
                    
                   
                }
                
                task.resume()
                
                return AnyCancellable{[weak task] in
                    task?.cancel()
                }
            }
    }
    
   
}
extension Encodable {
    func encode() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(self)
    }
    func encodeJson() -> String {
        
        do{
            let data = try JSONEncoder().encode(self)
            return String(data: data, encoding: String.Encoding.utf8) ?? ""
        }
        catch{
            print("error encode \(self) to JSON ")
            return ""
        }
    }
    
    var dictionaryValue:[String: Any?]? {
        guard let data = try? JSONEncoder().encode(self),
            let dictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                return nil
        }
        return dictionary
    }
    
    var dictionaryStringValue:[String: String]? {
        guard let data = try? JSONEncoder().encode(self),
            let dictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                return nil
        }
       
       
        var dic:[String:Any] = [:]
        dictionary.forEach{
            dic.append(anotherDict: [$0.key:"\($0.value)"])
        }
     
        return dic as? [String:String]
    }
    
    
}

extension Dictionary where Key == String, Value == Any {

    mutating func append(anotherDict:[String:Any]) {
        for (key, value) in anotherDict {
            self.updateValue(value, forKey: key)
        }
    }
}


extension Requester{
    
    private func processResult<DataResult:Decodable, CustomError:DecodError>(_ data:Data?,
                                                                             _ response:URLResponse?,
                                                                             _ error:Error?,
                                                                             subscriber: Publishers.Create<DataResult, CustomError>.Subscriber,
                                                                             request:URLRequest) {
        var token = "empty"
        
        do{
            
            token = try request.allHTTPHeaderFields?.tryValue(forKey: "Authorize") ?? ""
        }catch{
            
        }
        
        if error != nil {
         
            let customError = CustomError(error: error!)
        
            subscriber.send(completion: .failure(customError))
            
        }else{
        
            if let httpResponse = response as? HTTPURLResponse{
                let statusCode = httpResponse.statusCode
                
                do {
                    let _data = data ?? Data()
                    if statusCode == 200 {
                       
                        let objs = try decoder.decode(DataResult.self, from: _data)
                        subscriber.send(objs)
                        subscriber.send(completion: .finished)
                    } else {
                        var customError = CustomError(responseCode: httpResponse.statusCode)
                       
                        customError.errorInfo = "service \(httpResponse.url?.absoluteString ?? "") error \(httpResponse.statusCode) | token : \(token) | ==> \(String(data: _data, encoding: .utf8) ?? "")"
                        subscriber.send(completion: .failure(customError))
                    }
                } catch {
                    var customError = CustomError(responseCode: httpResponse.statusCode)
                    customError.errorInfo = "service \(httpResponse.url?.absoluteString ?? "") error typeMismatch | token : \(token) | ==> \(error)"
                    subscriber.send(completion: .failure(customError))
                }
            }else{
                let customError = CustomError(unknowError: "Error URLSession")
                subscriber.send(completion: .failure(customError))
            }
        }
    }
    func callUpload<DataResult:Decodable, CustomError:DecodError>(_ request: URLRequest, config:URLSessionConfiguration,isPreventPinning:Bool, dataUploadTask:Data?)
        -> AnyPublisher<DataResult, CustomError> {
            
            return AnyPublisher<DataResult, CustomError>.create { [weak self] subscriber in
                
            
                let sessionPinning = SessionPinningDelegate(statusPreventPinning: isPreventPinning);
                let urlSession = URLSession(configuration: config, delegate: sessionPinning, delegateQueue: nil)
                let task = urlSession.uploadTask(with: request, from:dataUploadTask) {
                    self?.processResult($0, $1, $2,
                                        subscriber: subscriber,
                                        request: request)
                }
                
                task.resume()
                
                return AnyCancellable {
                    task.cancel()
                }
            }
    }
}



public struct DictionaryTryValueError: Error {
    public init() {}
}

public extension Dictionary {
    func tryValue(forKey key: Key, error: Error = DictionaryTryValueError()) throws -> Value {
        guard let value = self[key] else { throw error }
        return value
    }
    
}
