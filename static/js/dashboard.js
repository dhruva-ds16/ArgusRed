document.addEventListener('DOMContentLoaded', function() {
    // Initialize Lucide icons
    lucide.createIcons();

    // Add status badge colors
    const statusBadges = document.querySelectorAll('.status-badge');
    statusBadges.forEach(badge => {
        const status = badge.dataset.status;
        const colors = {
            'planning': 'bg-yellow-100 text-yellow-800',
            'in-progress': 'bg-blue-100 text-blue-800',
            'completed': 'bg-green-100 text-green-800',
            'on-hold': 'bg-gray-100 text-gray-800'
        };
        badge.className += ` ${colors[status] || ''}`;
    });
});

// Tab switching functionality
function switchTab(tabName) {
    // Hide all tab contents
    document.querySelectorAll('.tab-content').forEach(tab => {
        tab.classList.add('hidden');
    });
    
    // Show selected tab content
    document.getElementById(`${tabName}-tab`).classList.remove('hidden');
    
    // Update tab button styles
    document.querySelectorAll('.tab-button').forEach(button => {
        button.classList.remove('border-b-2', 'border-red-600', 'text-red-600');
        button.classList.add('text-gray-500', 'hover:text-gray-700');
    });
    
    const activeButton = document.querySelector(`[data-tab="${tabName}"]`);
    activeButton.classList.add('border-b-2', 'border-red-600', 'text-red-600');
    activeButton.classList.remove('text-gray-500', 'hover:text-gray-700');
}