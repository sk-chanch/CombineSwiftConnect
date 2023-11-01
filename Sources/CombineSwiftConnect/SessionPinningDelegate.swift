//
//  SessionPinningDelegate.swift
//  RxSwiftConnect
//
//  Created by Sakon Ratanamalai on 2019/05/05.
//

import Foundation

public class SessionPinningDelegate: NSObject, URLSessionDelegate{
    
    private var isPreventPinning : Bool = false
    public init(statusPreventPinning:Bool){
        isPreventPinning = statusPreventPinning
    }
    
    public func urlSession(_ session: URLSession,
                           didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) {
        
      
        
        guard isPreventPinning
        else {
            //print("Not use Certificate")
            completionHandler(URLSession.AuthChallengeDisposition.performDefaultHandling, nil)
            return
        }
        
        
        //Adapted from OWASP https://www.owasp.org/index.php/Certificate_and_Public_Key_Pinning#iOS
        
        guard (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust)
        else { return }
        
        guard let serverTrust = challenge.protectionSpace.serverTrust
        else { return }
        
        var secresult:CFError?
        let status = SecTrustEvaluateWithError(serverTrust, &secresult)
        
        guard status
        else { return }
        
        guard let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0)
        else { return }
            
        let serverCertificateData = SecCertificateCopyData(serverCertificate)
        let data = CFDataGetBytePtr(serverCertificateData);
        let size = CFDataGetLength(serverCertificateData);
        let cert1 = NSData(bytes: data, length: size)
        let file_cer = Bundle.main.path(forResource: "certificate", ofType: "cer")
        
        guard let file = file_cer
        else { return }
        
        guard let cert2 = NSData(contentsOfFile: file)
        else { return }
        
        guard cert1.isEqual(to: cert2 as Data)
        else {
            //Pinning failed
            //print("failed Certificate")
            completionHandler(URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge, nil)
            return
        }
        
        //print("Trust Certificate")
        completionHandler(URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust:serverTrust))
        
        
    }
    
    
}
