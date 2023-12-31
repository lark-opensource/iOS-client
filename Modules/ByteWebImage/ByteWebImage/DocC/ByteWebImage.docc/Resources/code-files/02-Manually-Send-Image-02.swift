import ByteWebImage

let data = Data()

let result = ImageUploadChecker.getDataCheckResult(data: data)

switch result {
case .success:
    print("success")
case .failure(let checkError):
    print(checkError)
}
