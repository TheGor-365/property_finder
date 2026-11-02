require "test_helper"
require "rack/test"
require "tempfile"
require "zlib"

class ArticleCoverUploadTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    editor = Account.create!(
      email: "article-cover-#{SecureRandom.hex(6)}@example.test",
      password: "samplePassword2026!", password_confirmation: "samplePassword2026!",
      admin: true
    )
    sign_in editor
  end

  test "a licensed example PNG cover is stored with thumbnail and remains available after reload" do
    post_record = nil
    Tempfile.create(["pf-article-cover-", ".png"]) do |file|
      file.binmode
      file.write(valid_png)
      file.flush

      begin
        assert_difference "Post.count", 1 do
          post posts_path, params: {
            post: {
              title: "Illustrated example article",
              summary: "A sample editorial article with cover art.",
              body: "This sample article includes a test-only PNG cover.",
              active: true,
              image: Rack::Test::UploadedFile.new(file.path, "image/png", true)
            }
          }
        end

        post_record = Post.order(:id).last
        assert_redirected_to post_path(post_record)

        persisted = Post.find(post_record.id)
        assert persisted.image.present?
        assert File.file?(persisted.image.path), "Article cover original missing after reload"
        assert File.file?(persisted.image.thumb.path), "Article cover thumbnail missing after reload"

        get post_path(persisted)
        assert_response :success
      ensure
        post_record.image.remove! if post_record && post_record.image.present?
      end
    end
  end

  test "fake PNG is rejected without creating a public article" do
    Tempfile.create(["pf-invalid-cover-", ".png"]) do |file|
      file.binmode
      file.write("This is not a real PNG image.")
      file.flush

      assert_no_difference "Post.count" do
        post posts_path, params: {
          post: {
            title: "Should not publish",
            body: "A rejected cover must not be associated with a post.",
            active: true,
            image: Rack::Test::UploadedFile.new(file.path, "image/png", true)
          }
        }
      end
      assert_response :unprocessable_entity
      assert_select ".alert-danger", minimum: 1
    end
  end

  private

  def png_chunk(type, data)
    type = type.b
    [data.bytesize].pack("N") + type + data + [Zlib.crc32(type + data)].pack("N")
  end

  def valid_png
    width, height = 16, 16
    header = [width, height, 8, 2, 0, 0, 0].pack("NNCCCCC")
    row = "\x00".b + ("\x55\xAA\xCC".b * width)
    "\x89PNG\r\n\x1A\n".b +
      png_chunk("IHDR", header) +
      png_chunk("IDAT", Zlib::Deflate.deflate(row * height)) +
      png_chunk("IEND", "".b)
  end
end
