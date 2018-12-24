/*/ Sidebar
const $sidebar = document.querySelector("#sidebar");
if ($sidebar != null) {
  document.querySelector("#sidebar").addEventListener('click', function () {
    $sidebar.classList.toggle("active");
  });
}*/

// Sidebar
const $sidebar = document.querySelector("#sidebar");
const $sidebarToggle = document.querySelector("#sidebarToggle");
if ($sidebar != null && $sidebarToggle != null) {
  $sidebarToggle.addEventListener("click", function () {
    $sidebar.classList.toggle("active");
  });
}