<template>
  <span>
    <el-button
      v-if="columnName === 'LineDescription'"
      type="text"
      icon="el-icon-document-copy"
      @click.stop="onCopy"
    />

    <!-- Estado de Carga -->
    <div v-if="isLoading" class="loading-container">
      <i class="el-icon-loading" />
    </div>

    <component
      :is="editComponent"
      v-else-if="isEditing"
      v-bind="editComponentProps"
      :handle-change="onUpdate"
    />

    <span v-else>
      {{ displayValue }}
    </span>
  </span>
</template>

<script>
import EditAmount from '@/components/ADempiere/Form/VPOS2/MainOrder/OptionLine/editLine/editAmount.vue'
import EditQtyEntered from '@/components/ADempiere/Form/VPOS2/MainOrder/OptionLine/editLine/editQtyEntered.vue'

export default {
  name: 'EditableCell',
  components: {
    EditAmount,
    EditQtyEntered
  },
  props: {
    row: {
      type: Object,
      required: true
    },
    column: {
      type: Object,
      required: true
    },
    isLoading: {
      type: Boolean,
      default: false
    },
    displayValue: {
      type: [String, Number],
      default: ''
    },
    updateFunction: {
      type: Function,
      required: true
    },
    copyFunction: {
      type: Function,
      required: true
    }
  },
  computed: {
    columnName() {
      return this.column.columnName
    },
    isEditing() {
      switch (this.columnName) {
        case 'CurrentPrice':
          return this.row.isEditCurrentPrice
        case 'QtyEntered':
          return this.row.isEditQtyEntered
        case 'Discount':
          return this.row.isEditDiscount
        default:
          return false
      }
    },
    editComponent() {
      switch (this.columnName) {
        case 'CurrentPrice':
        case 'Discount':
          return 'EditAmount'
        case 'QtyEntered':
          return 'EditQtyEntered'
        default:
          return null
      }
    },
    editComponentProps() {
      switch (this.columnName) {
        case 'CurrentPrice':
          return { value: Number(this.row.price) }
        case 'QtyEntered':
          return { qty: Number(this.row.quantity_ordered) }
        case 'Discount':
          return { value: Number(this.row.discount_rate), precision: 0 }
        default:
          return {}
      }
    }
  },
  methods: {
    onUpdate(newValue) {
      this.updateFunction(newValue)
    },
    onCopy() {
      this.copyFunction(this.row)
    }
  }
}
</script>

<style scoped>
.loading-container {
  text-align: center;
  margin: 0;
}
.el-icon-loading {
  font-size: 20px;
}
</style>
