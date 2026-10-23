
import axios from 'axios';

const API_URL =
  window.APP_CONFIG?.API_URL || 'http://localhost:8080';

export default axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});