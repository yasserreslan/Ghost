resource "aws_s3_bucket" "bucket"{
    bucket = "ghost-bucket"
}

resource "aws_s3_bucket" "ghost_content" {
  bucket = "ghost-content-bucket"
  acl    = "private"
}
