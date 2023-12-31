protocol CaptchaAPI {
    /// captcha token 接口
    func captchaToken(method: String, body: String, result: @escaping (Result<String, V3LoginError>) -> Void)
}
