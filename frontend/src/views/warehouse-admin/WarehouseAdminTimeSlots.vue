<template>
  <Layout>
    <div>
      <div class="mb-8 flex justify-between items-center">
        <div>
          <h1 class="text-3xl font-bold text-gray-900">Time Slots Management</h1>
          <p class="mt-2 text-sm text-gray-600">Manage time slots for storage zones</p>
        </div>
        <div class="flex gap-2">
          <button @click="showTemplateModal = true" class="btn-secondary">
            Manage Templates
          </button>
          <button @click="generateNextDay" class="btn-secondary" :disabled="generating">
            {{ generating ? 'Generating...' : 'Generate Next Day' }}
          </button>
          <button @click="generateWeek" class="btn-secondary" :disabled="generating">
            {{ generating ? 'Generating...' : 'Generate Week' }}
          </button>
          <button @click="openCreateModal" class="btn-primary" :disabled="!selectedZone">
            Add Time Slot
          </button>
        </div>
      </div>

      <div class="mb-6">
        <select v-model="selectedZone" @change="loadTimeSlots" class="input-field max-w-md">
          <option value="">Select a Zone</option>
          <option v-for="zone in zones" :key="zone.zone_id" :value="zone.zone_id">
            {{ zone.name }} (Zone #{{ zone.zone_id }})
          </option>
        </select>
      </div>

      <div v-if="loading" class="text-center py-12">
        <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
        <p class="mt-2 text-gray-500">Loading time slots...</p>
      </div>

      <div v-else-if="!selectedZone" class="text-center py-12">
        <p class="text-gray-500">Please select a zone to view time slots</p>
      </div>

      <div v-else-if="timeSlots.length === 0" class="text-center py-12">
        <p class="text-gray-500 mb-4">No time slots found for this zone</p>
        <button @click="loadTimeSlots" class="btn-secondary">Retry</button>
      </div>

      <div v-else class="card overflow-hidden">
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Start Time</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">End Time</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr v-for="slot in timeSlots" :key="slot.time_id">
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  {{ formatDateTime(slot.start_at) }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  {{ formatDateTime(slot.end_at) }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span
                    class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full"
                    :class="slot.status === 'active' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'"
                  >
                    {{ slot.status }}
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                  <button
                    @click="editTimeSlot(slot)"
                    class="text-primary-600 hover:text-primary-900 mr-4"
                  >
                    Edit
                  </button>
                  <button
                    @click="deleteTimeSlot(slot.time_id)"
                    class="text-red-600 hover:text-red-900"
                    :disabled="deleting === slot.time_id"
                  >
                    {{ deleting === slot.time_id ? 'Deleting...' : 'Delete' }}
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Create/Edit Modal -->
      <div v-if="showCreateModal || editingTimeSlot" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
        <div class="bg-white rounded-lg p-6 max-w-md w-full mx-4">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">
            {{ editingTimeSlot ? 'Edit Time Slot' : 'Create Time Slot' }}
          </h2>
          <form @submit.prevent="saveTimeSlot">
            <div class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Zone</label>
                <select v-model.number="timeSlotForm.zone_id" required class="input-field">
                  <option value="">Select a zone</option>
                  <option v-for="zone in zones" :key="zone.zone_id" :value="zone.zone_id">
                    {{ zone.name }} (Zone #{{ zone.zone_id }})
                  </option>
                </select>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Start Time</label>
                <input v-model="timeSlotForm.start_at" type="datetime-local" required class="input-field" />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">End Time</label>
                <input 
                  v-model="timeSlotForm.end_at" 
                  type="datetime-local" 
                  required 
                  class="input-field"
                  :min="timeSlotForm.start_at || undefined"
                />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Status</label>
                <select v-model="timeSlotForm.status" required class="input-field">
                  <option value="active">Active</option>
                  <option value="not_active">Not Active</option>
                </select>
              </div>
            </div>
            <div class="mt-6 flex gap-3">
              <button type="submit" class="btn-primary flex-1" :disabled="saving">
                {{ saving ? 'Saving...' : 'Save' }}
              </button>
              <button type="button" @click="closeModal" class="btn-secondary flex-1">
                Cancel
              </button>
            </div>
          </form>
        </div>
      </div>

      <!-- Template Management Modal -->
      <div v-if="showTemplateModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
        <div class="bg-white rounded-lg p-6 max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto">
          <div class="flex justify-between items-start mb-4">
            <div>
              <h2 class="text-2xl font-bold text-gray-900">Time Slot Templates</h2>
              <p class="text-sm text-gray-600 mt-1 max-w-2xl">
                Templates define recurring time patterns (e.g., Monday 8:30-9:30, 10:30-11:30). 
                Use "Generate Next Day" or "Generate Week" buttons to create actual time slots from these templates. 
                When you change a template, it affects future time slot generation.
              </p>
            </div>
            <button @click="showTemplateModal = false" class="text-gray-500 hover:text-gray-700">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
          
          <div class="mb-4 flex gap-2">
            <button @click="openCreateTemplateModal" class="btn-primary">
              Add Single Template
            </button>
            <button @click="openBulkTemplateModal" class="btn-secondary">
              Add Multiple Templates (Bulk)
            </button>
          </div>

          <div v-if="templatesLoading" class="text-center py-8">
            <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
          </div>

          <div v-else-if="templates.length === 0" class="text-center py-8 text-gray-500">
            <p class="mb-2">No templates found.</p>
            <p class="text-sm">Create templates to automatically generate time slots. You can create multiple time ranges for the same day.</p>
          </div>

          <div v-else class="space-y-4">
            <!-- Group templates by day -->
            <div v-for="day in [0,1,2,3,4,5,6]" :key="day">
              <div v-if="getTemplatesForDay(day).length > 0" class="mb-4">
                <h3 class="font-semibold text-lg text-gray-900 mb-2">{{ getDayName(day) }}</h3>
                <div class="space-y-2">
                  <div v-for="template in getTemplatesForDay(day)" :key="template.template_id" class="border rounded-lg p-4 bg-gray-50">
                    <div class="flex justify-between items-start">
                      <div class="flex-1">
                        <div class="flex items-center gap-3">
                          <span class="font-medium text-primary-600">
                            {{ formatTime(template.start_time) }} - {{ formatTime(template.end_time) }}
                          </span>
                          <span class="text-xs text-gray-500">Zone #{{ template.zone_id }}</span>
                          <span v-if="template.max_appointments > 1" class="text-xs bg-blue-100 text-blue-800 px-2 py-1 rounded">
                            Max: {{ template.max_appointments }}
                          </span>
                        </div>
                      </div>
                      <div class="flex gap-2">
                        <button @click="editTemplate(template)" class="text-primary-600 hover:text-primary-900 text-sm font-medium">
                          Edit
                        </button>
                        <button @click="deleteTemplate(template.template_id)" class="text-red-600 hover:text-red-900 text-sm font-medium">
                          Delete
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Create/Edit Template Modal -->
      <div v-if="showCreateTemplateModal || editingTemplate" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
        <div class="bg-white rounded-lg p-6 max-w-md w-full mx-4">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">
            {{ editingTemplate ? 'Edit Template' : 'Create Template' }}
          </h2>
          <form @submit.prevent="saveTemplate">
            <div class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Zone</label>
                <select v-model.number="templateForm.zone_id" required class="input-field">
                  <option value="">Select a zone</option>
                  <option v-for="zone in zones" :key="zone.zone_id" :value="zone.zone_id">
                    {{ zone.name }} (Zone #{{ zone.zone_id }})
                  </option>
                </select>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Day of Week</label>
                <select v-model.number="templateForm.day_of_week" required class="input-field">
                  <option value="">Select day</option>
                  <option value="0">Monday</option>
                  <option value="1">Tuesday</option>
                  <option value="2">Wednesday</option>
                  <option value="3">Thursday</option>
                  <option value="4">Friday</option>
                  <option value="5">Saturday</option>
                  <option value="6">Sunday</option>
                </select>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Start Time</label>
                <input v-model="templateForm.start_time" type="time" required class="input-field" />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">End Time</label>
                <input 
                  v-model="templateForm.end_time" 
                  type="time" 
                  required 
                  class="input-field"
                  :min="templateForm.start_time || undefined"
                />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Max Appointments</label>
                <input 
                  v-model.number="templateForm.max_appointments" 
                  type="number" 
                  min="1" 
                  class="input-field"
                  placeholder="1"
                />
                <p class="text-xs text-gray-500 mt-1">Maximum number of appointments per time slot (default: 1)</p>
              </div>
            </div>
            <div class="mt-6 flex gap-3">
              <button type="submit" class="btn-primary flex-1" :disabled="savingTemplate">
                {{ savingTemplate ? 'Saving...' : 'Save' }}
              </button>
              <button type="button" @click="closeTemplateModal" class="btn-secondary flex-1">
                Cancel
              </button>
            </div>
          </form>
        </div>
      </div>

      <!-- Bulk Template Creation Modal -->
      <div v-if="showBulkTemplateModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
        <div class="bg-white rounded-lg p-6 max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto">
          <div class="flex justify-between items-center mb-4">
            <h2 class="text-2xl font-bold text-gray-900">Create Multiple Templates</h2>
            <button @click="closeBulkTemplateModal" class="text-gray-500 hover:text-gray-700">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
          
          <div class="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-4">
            <p class="text-sm text-blue-800">
              <strong>Bulk Template Creation:</strong> Create multiple time ranges for the same day and zone at once. 
              For example, create 5 different time slots for Monday (8:30-9:30, 10:30-11:30, etc.).
            </p>
          </div>

          <form @submit.prevent="saveBulkTemplates">
            <div class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Zone <span class="text-red-500">*</span></label>
                <select v-model.number="bulkTemplateForm.zone_id" required class="input-field">
                  <option value="">Select a zone</option>
                  <option v-for="zone in zones" :key="zone.zone_id" :value="zone.zone_id">
                    {{ zone.name }} (Zone #{{ zone.zone_id }})
                  </option>
                </select>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Day of Week <span class="text-red-500">*</span></label>
                <select v-model.number="bulkTemplateForm.day_of_week" required class="input-field">
                  <option value="">Select day</option>
                  <option value="0">Monday</option>
                  <option value="1">Tuesday</option>
                  <option value="2">Wednesday</option>
                  <option value="3">Thursday</option>
                  <option value="4">Friday</option>
                  <option value="5">Saturday</option>
                  <option value="6">Sunday</option>
                </select>
              </div>

              <div class="border-t pt-4">
                <div class="flex justify-between items-center mb-3">
                  <label class="block text-sm font-medium text-gray-700">Time Ranges <span class="text-red-500">*</span></label>
                  <button type="button" @click="addTimeRange" class="text-sm text-primary-600 hover:text-primary-900 font-medium">
                    + Add Another Time Range
                  </button>
                </div>
                
                <div v-for="(range, index) in bulkTemplateForm.timeRanges" :key="index" class="mb-4 p-4 border rounded-lg bg-gray-50">
                  <div class="flex justify-between items-start mb-2">
                    <span class="text-sm font-medium text-gray-700">Time Range {{ index + 1 }}</span>
                    <button 
                      v-if="bulkTemplateForm.timeRanges.length > 1" 
                      type="button" 
                      @click="removeTimeRange(index)" 
                      class="text-red-600 hover:text-red-900 text-sm"
                    >
                      Remove
                    </button>
                  </div>
                  <div class="grid grid-cols-2 gap-4">
                    <div>
                      <label class="block text-xs font-medium text-gray-600 mb-1">Start Time</label>
                      <input 
                        v-model="range.start_time" 
                        type="time" 
                        required 
                        class="input-field text-sm"
                        :min="index > 0 ? bulkTemplateForm.timeRanges[index - 1].end_time : undefined"
                      />
                    </div>
                    <div>
                      <label class="block text-xs font-medium text-gray-600 mb-1">End Time</label>
                      <input 
                        v-model="range.end_time" 
                        type="time" 
                        required 
                        class="input-field text-sm"
                        :min="range.start_time || undefined"
                      />
                    </div>
                  </div>
                  <div class="mt-2">
                    <label class="block text-xs font-medium text-gray-600 mb-1">Max Appointments</label>
                    <input 
                      v-model.number="range.max_appointments" 
                      type="number" 
                      min="1" 
                      class="input-field text-sm"
                      placeholder="1"
                    />
                  </div>
                </div>
              </div>
            </div>
            
            <div class="mt-6 flex gap-3">
              <button type="submit" class="btn-primary flex-1" :disabled="savingTemplate || !isBulkFormValid">
                {{ savingTemplate ? 'Creating...' : `Create ${bulkTemplateForm.timeRanges.length} Template(s)` }}
              </button>
              <button type="button" @click="closeBulkTemplateModal" class="btn-secondary flex-1">
                Cancel
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  </Layout>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { timeslotAPI } from '../../api/timeslot'
import { timeslotTemplateAPI } from '../../api/timeslottemplate'
import { zoneAPI } from '../../api/zone'
import Layout from '../../components/Layout.vue'

const timeSlots = ref([])
const zones = ref([])
const templates = ref([])
const loading = ref(false)
const templatesLoading = ref(false)
const selectedZone = ref('')
const showCreateModal = ref(false)
const showTemplateModal = ref(false)
const showCreateTemplateModal = ref(false)
const showBulkTemplateModal = ref(false)
const editingTimeSlot = ref(null)
const editingTemplate = ref(null)
const saving = ref(false)
const savingTemplate = ref(false)
const deleting = ref(null)
const generating = ref(false)
const bulkTemplateForm = ref({
  zone_id: null,
  day_of_week: null,
  timeRanges: [{ start_time: '', end_time: '', max_appointments: 1 }]
})

const timeSlotForm = ref({
  zone_id: null,
  start_at: '',
  end_at: '',
  status: 'active',
})

const templateForm = ref({
  zone_id: null,
  day_of_week: null,
  start_time: '',
  end_time: '',
  max_appointments: 1,
})

const loadZones = async () => {
  try {
    const response = await zoneAPI.getAll()
    zones.value = response.data || []
  } catch (error) {
    console.error('Error loading zones:', error)
    zones.value = []
  }
}

const loadTimeSlots = async () => {
  if (!selectedZone.value) {
    timeSlots.value = []
    loading.value = false
    return
  }
  
  loading.value = true
  try {
    const response = await timeslotAPI.getAll(selectedZone.value)
    // Ensure we get the data array from the response
    // The API returns { data: [...] } so we need to extract it
    const slots = response.data?.data || response.data || []
    timeSlots.value = Array.isArray(slots) ? slots : []
    
    // Removed debug logging to avoid Proxy object issues in console
  } catch (error) {
    console.error('Error loading time slots:', error)
    timeSlots.value = []
  } finally {
    loading.value = false
  }
}

const editTimeSlot = (slot) => {
  editingTimeSlot.value = slot
  timeSlotForm.value = {
    zone_id: slot.zone_id,
    start_at: formatDateTimeForInput(slot.start_at),
    end_at: formatDateTimeForInput(slot.end_at),
    status: slot.status,
  }
}

const openCreateModal = () => {
  editingTimeSlot.value = null
  timeSlotForm.value = {
    zone_id: selectedZone.value ? parseInt(selectedZone.value) : null,
    start_at: '',
    end_at: '',
    status: 'active',
  }
  showCreateModal.value = true
}

const closeModal = () => {
  showCreateModal.value = false
  editingTimeSlot.value = null
  timeSlotForm.value = {
    zone_id: selectedZone.value ? parseInt(selectedZone.value) : null,
    start_at: '',
    end_at: '',
    status: 'active',
  }
}

const openCreateTemplateModal = () => {
  editingTemplate.value = null
  templateForm.value = {
    zone_id: null,
    day_of_week: null,
    start_time: '',
    end_time: '',
    max_appointments: 1,
  }
  showCreateTemplateModal.value = true
}

const closeTemplateModal = () => {
  showCreateTemplateModal.value = false
  editingTemplate.value = null
  templateForm.value = {
    zone_id: null,
    day_of_week: null,
    start_time: '',
    end_time: '',
    max_appointments: 1,
  }
}

const openBulkTemplateModal = () => {
  bulkTemplateForm.value = {
    zone_id: null,
    day_of_week: null,
    timeRanges: [{ start_time: '', end_time: '', max_appointments: 1 }]
  }
  showBulkTemplateModal.value = true
}

const closeBulkTemplateModal = () => {
  showBulkTemplateModal.value = false
  bulkTemplateForm.value = {
    zone_id: null,
    day_of_week: null,
    timeRanges: [{ start_time: '', end_time: '', max_appointments: 1 }]
  }
}

const addTimeRange = () => {
  bulkTemplateForm.value.timeRanges.push({ start_time: '', end_time: '', max_appointments: 1 })
}

const removeTimeRange = (index) => {
  bulkTemplateForm.value.timeRanges.splice(index, 1)
}

const isBulkFormValid = computed(() => {
  if (!bulkTemplateForm.value.zone_id || bulkTemplateForm.value.day_of_week === null) {
    return false
  }
  return bulkTemplateForm.value.timeRanges.every(range => 
    range.start_time && range.end_time && range.end_time > range.start_time
  )
})

const saveBulkTemplates = async () => {
  if (!isBulkFormValid.value) {
    alert('Please fill in all required fields and ensure end times are after start times')
    return
  }

  savingTemplate.value = true
  try {
    const formatTime = (timeStr) => {
      return timeStr.includes(':') && timeStr.split(':').length === 2 
        ? timeStr + ':00' 
        : timeStr
    }

    let successCount = 0
    let errorCount = 0

    for (const range of bulkTemplateForm.value.timeRanges) {
      try {
        const data = {
          zone_id: parseInt(bulkTemplateForm.value.zone_id),
          day_of_week: parseInt(bulkTemplateForm.value.day_of_week),
          start_time: formatTime(range.start_time),
          end_time: formatTime(range.end_time),
          max_appointments: range.max_appointments || 1,
        }
        await timeslotTemplateAPI.create(data)
        successCount++
      } catch (error) {
        console.error('Error creating template:', error)
        errorCount++
      }
    }

    await loadTemplates()
    closeBulkTemplateModal()
    
    if (errorCount === 0) {
      alert(`✅ Successfully created ${successCount} template(s)!`)
    } else {
      alert(`⚠️ Created ${successCount} template(s), but ${errorCount} failed. Check console for details.`)
    }
  } catch (error) {
    console.error('Error saving bulk templates:', error)
    alert('❌ Failed to create templates: ' + (error.response?.data?.detail || error.message))
  } finally {
    savingTemplate.value = false
  }
}

const loadTemplates = async () => {
  templatesLoading.value = true
  try {
    const response = await timeslotTemplateAPI.getAll()
    templates.value = response.data || []
  } catch (error) {
    console.error('Error loading templates:', error)
    templates.value = []
  } finally {
    templatesLoading.value = false
  }
}

const saveTemplate = async () => {
  savingTemplate.value = true
  try {
    // Validate form
    if (!templateForm.value.zone_id) {
      alert('Please select a zone')
      savingTemplate.value = false
      return
    }

    if (templateForm.value.day_of_week === null || templateForm.value.day_of_week === '') {
      alert('Please select a day of the week')
      savingTemplate.value = false
      return
    }

    if (!templateForm.value.start_time || !templateForm.value.end_time) {
      alert('Please provide both start and end times')
      savingTemplate.value = false
      return
    }
    
    // Parse and validate time
    const [startHour, startMin] = templateForm.value.start_time.split(':').map(Number)
    const [endHour, endMin] = templateForm.value.end_time.split(':').map(Number)
    
    if (endHour < startHour || (endHour === startHour && endMin <= startMin)) {
      alert('End time must be after start time')
      savingTemplate.value = false
      return
    }
    
    // Format time as HH:MM:SS
    const formatTime = (timeStr) => {
      // time input gives HH:MM, we need HH:MM:SS
      return timeStr.includes(':') && timeStr.split(':').length === 2 
        ? timeStr + ':00' 
        : timeStr
    }
    
    const data = {
      zone_id: parseInt(templateForm.value.zone_id),
      day_of_week: parseInt(templateForm.value.day_of_week),
      start_time: formatTime(templateForm.value.start_time),
      end_time: formatTime(templateForm.value.end_time),
      max_appointments: templateForm.value.max_appointments || 1,
    }
    
    if (editingTemplate.value) {
      await timeslotTemplateAPI.update(editingTemplate.value.template_id, data)
      alert('✅ Template updated successfully!')
    } else {
      await timeslotTemplateAPI.create(data)
      alert('✅ Template created successfully!')
    }
    await loadTemplates()
    closeTemplateModal()
  } catch (error) {
    console.error('Error saving template:', error)
    const errorMsg = error.response?.data?.detail || error.message || 'Failed to save template'
    
    // Show more detailed error messages
    if (errorMsg.includes('end_time must be after start_time')) {
      alert('❌ End time must be after start time. Please correct the times and try again.')
    } else if (errorMsg.includes('day_of_week')) {
      alert('❌ Invalid day of week. Please select a valid day.')
    } else if (errorMsg.includes('zone')) {
      alert('❌ Invalid zone. Please select a valid zone.')
    } else {
      alert('❌ Failed to save template: ' + errorMsg)
    }
  } finally {
    savingTemplate.value = false
  }
}

const editTemplate = (template) => {
  editingTemplate.value = template
  // Safely extract time strings
  const getTimeString = (timeValue) => {
    if (!timeValue) return ''
    if (typeof timeValue === 'string') {
      return timeValue.length >= 5 ? timeValue.substring(0, 5) : timeValue
    }
    // If it's a time object, convert to string first
    return String(timeValue).substring(0, 5)
  }
  
  templateForm.value = {
    zone_id: template.zone_id,
    day_of_week: template.day_of_week,
    start_time: getTimeString(template.start_time),
    end_time: getTimeString(template.end_time),
    max_appointments: template.max_appointments || 1,
  }
}

const deleteTemplate = async (templateId) => {
  if (!confirm('Are you sure you want to delete this template?')) return
  
  try {
    await timeslotTemplateAPI.delete(templateId)
    await loadTemplates()
  } catch (error) {
    console.error('Error deleting template:', error)
    alert('Failed to delete template')
  }
}

const getDayName = (dayOfWeek) => {
  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
  return days[dayOfWeek] || 'Unknown'
}

const getTemplatesForDay = (dayOfWeek) => {
  return templates.value.filter(t => t.day_of_week === dayOfWeek)
}

const formatTime = (timeString) => {
  if (!timeString) return ''
  try {
    // Handle different time formats
    if (typeof timeString === 'string') {
      // If it's already in HH:MM format
      if (timeString.length >= 5) {
        return timeString.substring(0, 5)
      }
      // If it's in HH:MM:SS format
      if (timeString.includes(':')) {
        const parts = timeString.split(':')
        return `${parts[0]}:${parts[1]}`
      }
    }
    // If it's a time object or other format, try to convert
    return String(timeString).substring(0, 5)
  } catch (error) {
    console.error('Error formatting time:', error, timeString)
    return 'Invalid'
  }
}

const saveTimeSlot = async () => {
  saving.value = true
  try {
    // Validate form
    if (!timeSlotForm.value.zone_id) {
      alert('Please select a zone')
      saving.value = false
      return
    }

    if (!timeSlotForm.value.start_at || !timeSlotForm.value.end_at) {
      alert('Please provide both start and end times')
      saving.value = false
      return
    }

    // Validate that end time is after start time
    const startDate = new Date(timeSlotForm.value.start_at)
    const endDate = new Date(timeSlotForm.value.end_at)
    
    if (endDate <= startDate) {
      alert('End time must be after start time')
      saving.value = false
      return
    }

    // Format datetime for API (ensure it's in ISO format without timezone issues)
    const formatDateTime = (dateTimeLocal) => {
      // datetime-local gives us YYYY-MM-DDTHH:mm format
      // We need to convert it to ISO format
      const date = new Date(dateTimeLocal)
      // Get local time components
      const year = date.getFullYear()
      const month = String(date.getMonth() + 1).padStart(2, '0')
      const day = String(date.getDate()).padStart(2, '0')
      const hours = String(date.getHours()).padStart(2, '0')
      const minutes = String(date.getMinutes()).padStart(2, '0')
      const seconds = String(date.getSeconds()).padStart(2, '0')
      return `${year}-${month}-${day}T${hours}:${minutes}:${seconds}`
    }

    const data = {
      zone_id: parseInt(timeSlotForm.value.zone_id),
      start_at: formatDateTime(timeSlotForm.value.start_at),
      end_at: formatDateTime(timeSlotForm.value.end_at),
      status: timeSlotForm.value.status,
    }
    
    if (editingTimeSlot.value) {
      await timeslotAPI.update(editingTimeSlot.value.time_id, data)
      alert('✅ Time slot updated successfully!')
    } else {
      await timeslotAPI.create(data)
      alert('✅ Time slot created successfully!')
    }
    await loadTimeSlots()
    closeModal()
  } catch (error) {
    console.error('Error saving time slot:', error)
    const errorMsg = error.response?.data?.detail || error.message || 'Failed to save time slot'
    alert('❌ Failed to save time slot: ' + errorMsg)
  } finally {
    saving.value = false
  }
}

const deleteTimeSlot = async (timeId) => {
  if (!confirm('Are you sure you want to delete this time slot?')) return
  
  deleting.value = timeId
  try {
    await timeslotAPI.delete(timeId)
    await loadTimeSlots()
  } catch (error) {
    console.error('Error deleting time slot:', error)
    alert('Failed to delete time slot')
  } finally {
    deleting.value = null
  }
}

const generateNextDay = async () => {
  generating.value = true
  try {
    const response = await timeslotAPI.generateNextDay()
    const result = response.data || {}
    const count = result.count || 0
    const message = result.message || `Generated ${count} time slots for next day`
    
    if (count === 0) {
      alert('⚠️ ' + message + '\n\nTip: Create templates for tomorrow\'s weekday first, or slots may already exist for those times.')
    } else {
      alert('✅ ' + message)
    }
    
    if (selectedZone.value) {
      await loadTimeSlots()
    }
  } catch (error) {
    console.error('Error generating time slots:', error)
    const errorMsg = error.response?.data?.detail || error.message || 'Failed to generate time slots. Make sure you have templates created for tomorrow\'s weekday.'
    alert('❌ Failed to generate time slots: ' + errorMsg)
  } finally {
    generating.value = false
  }
}

const generateWeek = async () => {
  generating.value = true
  try {
    const response = await timeslotAPI.generateWeek()
    const result = response.data || {}
    const count = result.count || 0
    const message = result.message || `Generated ${count} time slots for next week`
    
    if (count === 0) {
      alert('⚠️ ' + message + '\n\nTip: Create templates for the upcoming weekdays first, or slots may already exist for those times.')
    } else {
      alert('✅ ' + message)
    }
    
    if (selectedZone.value) {
      await loadTimeSlots()
    }
  } catch (error) {
    console.error('Error generating time slots:', error)
    const errorMsg = error.response?.data?.detail || error.message || 'Failed to generate time slots. Make sure you have templates created.'
    alert('❌ Failed to generate time slots: ' + errorMsg)
  } finally {
    generating.value = false
  }
}

const formatDateTime = (dateString) => {
  if (!dateString) return 'N/A'
  try {
    // Handle ISO datetime strings
    const date = new Date(dateString)
    
    // Check if date is valid
    if (isNaN(date.getTime())) {
      console.error('Invalid date:', dateString)
      return 'Invalid Date'
    }
    
    return date.toLocaleString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      hour12: true
    })
  } catch (error) {
    console.error('Error formatting date:', error, dateString)
    return 'Invalid Date'
  }
}

const formatDateTimeForInput = (dateString) => {
  if (!dateString) return ''
  try {
    const date = new Date(dateString)
    // Handle timezone by using local time components
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    const hours = String(date.getHours()).padStart(2, '0')
    const minutes = String(date.getMinutes()).padStart(2, '0')
    return `${year}-${month}-${day}T${hours}:${minutes}`
  } catch (error) {
    console.error('Error formatting date:', error, dateString)
    return ''
  }
}

onMounted(async () => {
  await loadZones()
  await loadTemplates()
})
</script>

