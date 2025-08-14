using Microsoft.AspNetCore.Mvc;
using QLCCCC.Models;
using QLCCCC.Repositories;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using System.IO;
using System.Net.Http;
using System.Net.Http.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System.Text.Json;


namespace QLCCCC.Controllers
{
    public class TinTucController : Controller
    {
        private readonly ITinTucRepository _repository;
        private readonly IWebHostEnvironment _environment;
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly IConfiguration _config;
        private readonly ILogger<TinTucController> _logger; // ✅ Thêm logger

        public TinTucController(
            ITinTucRepository repository,
            IWebHostEnvironment environment,
            IHttpClientFactory httpClientFactory,
            IConfiguration config,
            ILogger<TinTucController> logger) // ✅ Inject logger
        {
            _repository = repository;
            _environment = environment;
            _httpClientFactory = httpClientFactory;
            _config = config;
            _logger = logger; // ✅ Gán logger
        }

        public async Task<IActionResult> Index()
        {
            var tinTucs = await _repository.GetAllAsync();
            return View(tinTucs);
        }

        public async Task<IActionResult> Details(int id)
        {
            var tinTuc = await _repository.GetByIdAsync(id);
            if (tinTuc == null) return NotFound();
            return View(tinTuc);
        }

        public IActionResult Create()
        {
            return View();
        }

      [HttpPost]
[ValidateAntiForgeryToken]
public async Task<IActionResult> Create(TinTuc tinTuc, IFormFile hinhAnh)
{
    if (!ModelState.IsValid)
    {
        _logger.LogWarning("ModelState invalid, không tạo tin tức.");
        return View(tinTuc);
    }

    string imgbbUrlPublic = null;

    // 1. Upload ảnh vào wwwroot/images
    if (hinhAnh != null && hinhAnh.Length > 0)
    {
        var fileName = Path.GetFileNameWithoutExtension(hinhAnh.FileName) 
                       + "_" + Guid.NewGuid() 
                       + Path.GetExtension(hinhAnh.FileName);
        var filePath = Path.Combine(_environment.WebRootPath, "images", fileName);

        using (var stream = new FileStream(filePath, FileMode.Create))
        {
            await hinhAnh.CopyToAsync(stream);
        }

        tinTuc.HinhAnh = "/images/" + fileName;

        // 2. Upload ảnh lên imgbb
        using var memoryStream = new MemoryStream();
        await hinhAnh.CopyToAsync(memoryStream);
        var imageBytes = memoryStream.ToArray();
        var base64Image = Convert.ToBase64String(imageBytes);

        var imgbbKey = "1dad6dd4799a346374528b9a32909456";
        var imgbbApiUrl = $"https://api.imgbb.com/1/upload?key={imgbbKey}";

        using var formContent = new MultipartFormDataContent();
        formContent.Add(new StringContent(base64Image), "image");

        var client = _httpClientFactory.CreateClient();
        var imgbbResponse = await client.PostAsync(imgbbApiUrl, formContent);

        if (imgbbResponse.IsSuccessStatusCode)
        {
            var jsonString = await imgbbResponse.Content.ReadAsStringAsync();
            using var doc = JsonDocument.Parse(jsonString);
            imgbbUrlPublic = doc.RootElement.GetProperty("data").GetProperty("url").GetString();
        }
        else
        {
            _logger.LogError("Upload ảnh lên imgbb thất bại: {Status}", imgbbResponse.StatusCode);
        }
    }

    // 3. Lưu vào DB (ảnh local)
    await _repository.AddAsync(tinTuc);
    _logger.LogInformation("Tin tức '{Title}' đã lưu vào DB", tinTuc.TieuDe);

    // 4. Gửi webhook tới n8n (ảnh dùng link imgbb nếu có)
    var webhookUrl = _config["N8n:WebhookUrl"];
    if (string.IsNullOrEmpty(webhookUrl))
    {
        _logger.LogError("Webhook URL chưa được cấu hình!");
        return RedirectToAction(nameof(Index));
    }

    var payload = new
    {
        title = tinTuc.TieuDe,
        content = tinTuc.NoiDung,
        imageUrl = imgbbUrlPublic ?? $"{Request.Scheme}://{Request.Host}{tinTuc.HinhAnh}"
    };

    try
    {
        var client = _httpClientFactory.CreateClient();
        var response = await client.PostAsJsonAsync(webhookUrl, payload);

        if (response.IsSuccessStatusCode)
        {
            _logger.LogInformation("Webhook gửi thành công tới n8n: {WebhookUrl}", webhookUrl);
        }
        else
        {
            var errorContent = await response.Content.ReadAsStringAsync();
            _logger.LogError("Webhook gửi thất bại ({Status}): {Error}", response.StatusCode, errorContent);
        }
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Lỗi khi gửi webhook tới n8n");
    }

    return RedirectToAction(nameof(Index));
}

        public async Task<IActionResult> Edit(int id)
        {
            var tinTuc = await _repository.GetByIdAsync(id);
            if (tinTuc == null) return NotFound();
            return View(tinTuc);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(TinTuc tinTuc, IFormFile? hinhAnh)
        {
            if (!ModelState.IsValid)
            {
                return View(tinTuc);
            }

            // Xử lý tải lên hình ảnh mới nếu có
            if (hinhAnh != null && hinhAnh.Length > 0)
            {
                var fileName = Path.GetFileNameWithoutExtension(hinhAnh.FileName) + "_" + Guid.NewGuid() + Path.GetExtension(hinhAnh.FileName);
                var filePath = Path.Combine(_environment.WebRootPath, "images", fileName);

                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await hinhAnh.CopyToAsync(stream);
                }

                // Xóa hình ảnh cũ nếu có
                if (!string.IsNullOrEmpty(tinTuc.HinhAnh))
                {
                    var oldFilePath = Path.Combine(_environment.WebRootPath, tinTuc.HinhAnh.TrimStart('/'));
                    if (System.IO.File.Exists(oldFilePath))
                    {
                        System.IO.File.Delete(oldFilePath);
                    }
                }

                tinTuc.HinhAnh = "/images/" + fileName;
            }

            await _repository.UpdateAsync(tinTuc);
            return RedirectToAction(nameof(Index));
        }

        public async Task<IActionResult> Delete(int id)
        {
            var tinTuc = await _repository.GetByIdAsync(id);
            if (tinTuc == null) return NotFound();
            return View(tinTuc);
        }

        [HttpPost, ActionName("DeleteConfirmed")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> DeleteConfirmed(int id)
        {
            var tinTuc = await _repository.GetByIdAsync(id);
            if (tinTuc != null)
            {
                // Xóa hình ảnh nếu có
                if (!string.IsNullOrEmpty(tinTuc.HinhAnh))
                {
                    var filePath = Path.Combine(_environment.WebRootPath, tinTuc.HinhAnh.TrimStart('/'));
                    if (System.IO.File.Exists(filePath))
                    {
                        System.IO.File.Delete(filePath);
                    }
                }

                await _repository.DeleteAsync(id);
            }
            return RedirectToAction(nameof(Index));
        }
    }
}
